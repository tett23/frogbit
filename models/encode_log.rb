# coding: utf-8

class EncodeLog
  include DataMapper::Resource

  property :id, Serial
  property :body, Text
  property :start_at, DateTime
  property :finish_at, DateTime
  property :status, Enum[:failure, :success, :in_progress]
  property :width, Integer
  property :height, Integer
  property :filename, String
  property :filesize, String
  property :created_at, DateTime

  belongs_to :video, :unique=>false

  def self.list(options={})
    default = {
      order: :created_at.desc
    }
    options = default.merge(options)

    all(options)
  end

  def self.logs(video)
    all(
      video: video,
      order: :created_at.desc
    )
  end

  def self.start(encode_queue)
    self.create({
      start_at: Time.now,
      status: :in_progress,
      video: encode_queue.video
    })
  end

  def finish(result)
    status = result[:result] ? :success : :failure

    self.update({
      body: result[:message],
      finish_at: Time.now,
      status: status,
      filename: result[:filename],
      filesize: result[:filesize],
      width: result[:width],
      height: result[:height]
    })
  end

  def output_size
    (self.width && self.height) ? "#{self.width}x#{self.height}" : nil
  end
end
