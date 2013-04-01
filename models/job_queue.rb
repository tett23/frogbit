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
    JobQueue.create(
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

    self.process()
    add_log(eval(self.callback).call.to_s) unless self.callback.blank?

    result_hash(true, log)
  end

  def process
    begin
      case self.type
      when :encode
        add_log self.video.repair()
      when :repair
        encode_queue = EncodeQueue.all(video: self.video).first
        add_log EncodeBackend.encode(EncodeQueue.all(encode_queue))
      else
        add_log '未定義のジョブ'
      end
    rescue
      add_log($!)
      add_log($!.backtrace.join("\n"))
    end
  end

  def self.running?
    count = self.all(is_running: true).count

    !count.zero?
  end

  def self.running
    self.all(is_running: true)
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
