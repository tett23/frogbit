# coding: utf-8

class VideoMetadata
  include DataMapper::Resource

  property :id, Serial
  property :is_subtitle, Boolean
  property :is_digital, Boolean
end
