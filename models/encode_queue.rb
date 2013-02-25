# coding: utf-8

class EncodeQueue
  include DataMapper::Resource

  property :id, Serial
  property :priority, Integer, :default=>100
  property :created_at, DateTime

  has 1, :video
end
