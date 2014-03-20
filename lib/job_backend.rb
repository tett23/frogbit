# coding: utf-8

require 'singleton'

class JobBackend
  include Singleton

  def initialize
    @running_items = JobQueue.running.map do |job|
      job.id
    end
  end

  def process(job)
    return false if job.nil?

    EM.defer do
      execute_job(job)
    end
  end

  def process_all
    return unless @running_items.size.zero?

    EM.defer do
      while job = JobQueue.shift
        execute_job(job) if @running_items.size.zero?
        sleep 1
      end
    end
  end

  private
  def execute_job(job)
    return if job.nil?
    @running_items << job.id

    begin
      log = JobLog.all(job_queue_id: job.id).first
      log = JobLog.start(job) if log.nil?

      result = job.execute(force: true)
      log.finish(result)
    rescue
      error = "#{$!.to_s}\n#{$!.backtrace.join("\n")}"
      puts error
      log = JobLog.all(job_queue_id: job.id).first

      log.finish(
        result: false,
        log: error
      ) unless log.nil?
    ensure
      job.destroy
      delete_running_item(job)
    end
  end

  def delete_running_item(job)
    @running_items.delete_if do |item|
      item == job.id
    end
  end
end
