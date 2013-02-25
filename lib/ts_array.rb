# coding: utf-8

class TSArray < Array
  def find(identification_code)
    idx = self.index do |ts|
      ts.identification_code == identification_code
    end

    return nil if idx.nil?

    self.fetch(idx)
  end
end
