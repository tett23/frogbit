# coding: utf-8

class FilterRegexp
  include DataMapper::Resource

  TARGET_LIST = [
    :filename,
    :description,
    :program
  ]

  property :id, Serial
  property :target, Enum[*FilterRegexp::TARGET_LIST]
  property :regexp, String
  property :alter, String
  property :created_at, DateTime
  property :updated_at, DateTime

  belongs_to :series, :required=>false

  validates_with_method :check_valid_regexp
  validates_with_method :check_target_and_regexp

  def self.list(options={})
    default = {
      order: [:updated_at.desc]
    }
    options = default.merge(options)

    all(options)
  end

  def name
    "#{self.regexp}, #{self.alter}"
  end

  private
  def check_valid_regexp
    Regexp.new(self.regexp) rescue [false, '妥当な正規表現でない']

    true
  end

  def check_target_and_regexp
    aleady_exest = FilterRegexp.get(
      target: self.target,
      regexp: self.regexp
    )

    return true if aleady_exest.blank?

    [false, 'すでに存在するルール']
  end
end
