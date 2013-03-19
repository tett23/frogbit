# coding: utf-8

class EncodeLog
  include DataMapper::Resource

  property :id, Serial
  property :body, Text
  property :start_at, DateTime
  property :finish_at, DateTime
  property :status, Enum[:failure, :success], :default=>:failure
  property :created_at, DateTime

  belongs_to :video, :unique=>false
end
