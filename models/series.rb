# coding: utf-8

class Series
  include DataMapper::Resource

  property :id, Serial
  property :name, String
  property :period, Integer
end
