# coding: utf-8

class EncodeQueue
  include DataMapper::Resource

  property :id, Serial
  property :priority, Integer, :default=>100
  property :created_at, DateTime

  belongs_to :video, :unique=>true

  def self.add_last(video_id)
    encode_queue = EncodeQueue.get(:video_id=>video_id)
    return encode_queue unless encode_queue.nil?

    self.create({
      priority: self.last_priority(),
      video_id: video_id
    })
  end

  def self.last_priority
    encode_queue = self.all(:order=>:priority.desc).first
    p encode_queue

    return 1 if encode_queue.nil?

    encode_queue.priority+1
  end
end
