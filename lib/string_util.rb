class String
  def is_integer?
    self.to_s.to_i.to_s == self.to_s
  end

  def str_int_rep
    # p self
    self.is_integer? ? self : "'#{self}'" 
  end
end

