require_relative 'utils'
class Array
  # find a random value in the array that is not eqaul to the value
  def find_random_dif(value)
    newArray = self.select{|val| val != value } 
    rand = Utils.rand_in_bounds(0, newArray.length)
    newArray[rand]
  end

end
