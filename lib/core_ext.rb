# coding: utf-8

class String
  def to_boolean
    return true if self == 'true'
    return false if self == 'false'

    nil
  end
end
