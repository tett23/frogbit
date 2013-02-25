# coding: utf-8

class EncodeQueue
  include DataMapper::Resource

  property :id, Serial
  property :priority, Integer, :default=>100
  property :created_at, DateTime

  belongs_to :video, :unique=>true

  def self.highest_priority_item
    return nil if self.count.zero?

    self.first(:order=>:priority.asc)
  end

  def self.add_last(video_id)
    encode_queue = EncodeQueue.get(:video_id=>video_id)
    return encode_queue unless encode_queue.nil?
    video = Video.get(video_id)
    return encode_queue if video.is_encoded

    self.create({
      priority: self.last_priority(),
      video_id: video_id
    })
  end

  def self.last_priority
    encode_queue = self.all(:order=>:priority.desc).first

    return 1 if encode_queue.nil?

    encode_queue.priority+1
  end
end
