# coding: utf-8

class Video
  include DataMapper::Resource

  property :id, Serial
  property :identification_code, String, :unique=>true
  property :name, String, :required=>true
  property :episode, Integer
  property :original_name, String
  property :saved_directory, String
  property :extension, Enum[:ts, :mp4, :avi]
  property :is_encoded, Boolean, :default=>false
  property :is_watched, Boolean, :default=>false
  property :program, Text
  property :encode_log, Text
  property :recording_error, Text
  property :created_at, DateTime
  property :updated_at, DateTime

  belongs_to :series, :required=>false
  belongs_to :video_metadata, :required=>false
end
