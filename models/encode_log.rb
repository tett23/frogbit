# coding: utf-8

class EncodeLog
  include DataMapper::Resource

  property :id, Serial
  property :body, Text
  property :start_at, DateTime
  property :finish_at, DateTime
  property :status, Enum[:failure, :success, :in_progress]
  property :created_at, DateTime

  belongs_to :video, :unique=>false

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
      status: status
    })
  end
end
