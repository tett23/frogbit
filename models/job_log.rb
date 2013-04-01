# coding: utf-8

class JobLog
  include DataMapper::Resource

  property :id, Serial
  property :body, Text
  property :start_at, DateTime
  property :finish_at, DateTime
  property :status, Enum[:failure, :success, :in_progress]
  property :created_at, DateTime

  belongs_to :job_queue, :required=>false
  belongs_to :video, :unique=>false

  def self.list(options={})
    default = {
      order: :created_at.desc
    }
    options = default.merge(options)

    all(options)
  end

  def self.start(job)
    create(
      job_queue: job,
      video: job.video,
      start_at: Time.now,
      status: :in_progress
    )
  end

  def finish(result)
    status = result[:result] ? :success : :failure

    self.update(
      body: result[:log],
      finish_at: Time.now,
      status: status
    )
  end
end
