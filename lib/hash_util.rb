require 'jsonpath'
class Hash
  def find_all_values_for(key)
    result = []
    result << self[key] unless self[key].nil?
    self.values.each do |hash_value|
      # p "hash_value: #{hash_value}"
      unless hash_value.is_a? Array
        values = [hash_value]
        values.each do |value|
          result += value.find_all_values_for(key) if value.is_a? Hash
        end
      end
    end
    result.compact
    #pp result.to_a
  end
  def find_and_update(key,value,new_value)
    JsonPath.for(self.to_json).gsub('$..#{key}:[#{value}]') {|v| new_value }.to_hash
  end
end

