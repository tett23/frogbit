# coding: utf-8

class Video
  include DataMapper::Resource

  property :id, Serial
  property :name, String, :required=>false
  property :original_name, String
  property :recording_error, Text
  property :program, Text
  property :saved_directory, String
  property :extension, Enum[:ts, :mp4, :avi]
  property :episode, Integer
  property :is_encoded, Boolean, :default=>false
  property :is_watched, Boolean, :default=>false
  property :created_at, DateTime
  property :updated_at, DateTime

  belongs_to :series, :required=>false
  has 1, :video_metadata
end
