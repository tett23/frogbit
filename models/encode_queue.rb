# coding: utf-8

class EncodeQueue
  include DataMapper::Resource

  property :id, Serial
  property :width, Integer, :default=>1440
  property :height, Integer, :default=>1080
  property :is_encoding, Boolean, :default=>false
  property :created_at, DateTime

  belongs_to :video, :unique=>true

  ENCODE_SIZE = [
    '1440x1080',
    '1280x720',
    '480x360'
  ]

  def self.add_last(video_id, options={})
    encode_queue = EncodeQueue.get(:video_id=>video_id)
    return encode_queue unless encode_queue.nil?

    unless options[:force]
      video = Video.get(video_id)
      return encode_queue if video.is_encoded
    end

    self.create({
      video_id: video_id
    })
  end

  def self.list(options={})
    default = {
      order: :created_at.asc
    }
    options = default.merge(options)

    all(options)
  end

  def encodable?
    !self.video.output_name.blank?
  end

  def encode
    if self.is_encoding
      return {
        result: false,
        message: 'エンコード中'
      }
    end

    in_path = self.input_path
    out_path = "./out/#{self.video.output_name}"
    command = "sh ts2mp4.sh '#{in_path}' '#{out_path}' #{self.width} #{self.height}"

    unless File.exists?(in_path)
      return {
        result: false,
        command: command,
        message: 'tsが存在しない'
      }
    end

    self.update(:is_encoding => true)

    out = ''
    command_result = systemu(command, :out=>out)
    p command_result

    unless File.exists?(out_path)
      return {
        result: false,
        command: command,
        message: 'ファイルが生成されていない？'
      }
    end

    unless FileUtils.mv(out_path, self.output_path)
      self.update(:is_encoding => false)

      return {
        result: false,
        command: command,
        message: 'ファイルの移動に失敗。NASが起動していない？'
      }
    end

    unless self.video.repaired_ts.blank?
      FileUtils.rm(self.video.repaired_ts)
    end

    {
      result: true,
      command: command,
      message: '正常に終了',
      command_result: command_result,
      log: out,
      filename: self.video.output_name,
      filesize: self.filesize,
      width: self.width,
      height: self.height
    }
  end

  def input_path
    original_ts = "#{$config[:input_dir]}/#{self.video.original_name}"

    self.video.repaired_ts.blank? ? original_ts : self.video.repaired_ts
  end

  def output_path
    "#{$config[:output_dir]}/#{self.video.output_name}"
  end

  def filesize
    size = nil
    if File.exists?(self.output_path)
      size = File.stat(self.output_path).size
    end

    size
  end

  def output_size
    (self.width && self.height) ? "#{self.width}x#{self.height}" : nil
  end

  def update_size(size)
    width, height = size.split('x')

    self.update(width: width, height: height)
  end
end
