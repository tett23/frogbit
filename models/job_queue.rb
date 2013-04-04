# coding: utf-8

class JobQueue
  include DataMapper::Resource

  property :id, Serial
  property :type, Enum[:encode, :repair]
  property :priority, Integer, :default=>lambda {|r, p|
    JobQueue.last_priority
  }
  property :callback, Text
  property :is_running, Boolean, :default=>false
  property :created_at, DateTime
  property :updated_at, DateTime

  belongs_to :video, :unique=>false

  def self.list(options={})
    default = {
      order: :priority.asc
    }
    options = default.merge(options)

    all(options)
  end

  def self.last_priority
    queue = JobQueue.all(:order=>:priority.desc).first
    return 1 if queue.nil?

    queue.priority+1
  end

  # proc渡すと条件絞って取れるとか
  def self.pop(&block)
    job = self.all(order: :priority.desc).first
    return nil if job.nil?

    job
  end

  def self.shift(&block)
    job = self.all(order: :priority).first
    return nil if job.nil?

    job
  end

  def self.push(video, type)
    job = JobQueue.get(video_id: video.id, type: type)
    return job unless job.nil?

    JobQueue.first_or_create(
      video: video,
      type: type
    )
  end

  def execute(options={})
    default = {
      force: false
    }
    options = default.merge(options)

    return result_hash(false, '処理中のジョブ') if self.is_running

    if JobQueue.running? && !options[:force]
      return result_hash(false, '処理中')
    end

    self.update(is_running: true)

    result = self.process()
    unless result && self.callback.blank?
      add_log(eval(self.callback).call.to_s) rescue result = false
    end

    result_hash(result, log)
  end

  def process
    begin
      case self.type
      when :repair
        add_log self.video.repair()
      when :encode
        encode_queue = EncodeQueue.all(video: self.video).first
        add_log EncodeBackend.instance.encode(encode_queue)
      else
        add_log '未定義のジョブ'
      end
    rescue
      add_log($!)
      add_log($!.backtrace.join("\n"))

      return false
    end

    true
  end

  def self.running?
    count = self.all(is_running: true).count

    !count.zero?
  end

  def self.running
    self.all(is_running: true)
  end

  def up
    job = JobQueue.first(:priority.lt =>self.priority, :order=>:priority.desc)
    return false if job.nil?

    current_priority = self.priority
    target_priority = job.priority

    job.update(:priority=>current_priority)
    self.update(:priority=>target_priority)
  end

  def down
    job = JobQueue.first(:priority.gt =>self.priority, :order=>:priority.asc)
    return false if job.nil?

    current_priority = self.priority
    target_priority = job.priority

    job.update(:priority=>current_priority)
    self.update(:priority=>target_priority)
  end

  private
  def result_hash(result, log)
    {
      result: result,
      log: log
    }
  end

  def add_log(message)
    @log ||= ''

    message = message.to_s
    @log = (@log.blank? ? message : @log+"\n"+message)
  end

  def log
    @log
  end
end
