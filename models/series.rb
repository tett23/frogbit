# coding: utf-8

class Series
  include DataMapper::Resource

  property :id, Serial
  property :name, String, :required=>true
  property :alt_name, String
  property :period, Integer, :default=>1
  property :created_at, DateTime
  property :updated_at, DateTime

  has n, :videos

  def self.list(options={})
    default = {
      order: [:name, :period, :id.desc]
    }
    options = default.merge(options)

    all(options)
  end

  def self.add_or_first(series)
    return nil if series[:name].blank?
    series = Series.first(name: series[:name]) || Series.first(alt_name: series[:name])

    return series unless series.blank?

    Series.create(series)
  end
end
