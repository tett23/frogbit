# coding: utf-8

class EncodeQueue
  include DataMapper::Resource

  property :id, Serial
  property :priority, Integer, :default=>100
  property :created_at, DateTime

  belongs_to :video, :required=>false
end
