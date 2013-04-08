# coding: utf-8

class FilterRegexp
  include DataMapper::Resource

  property :id, Serial
  property :target, Enum[:filename, :description, :program]
  property :regexp, Regexp
  property :alter, String

  belongs_to :series, :required=>false
end
