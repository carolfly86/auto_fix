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
  def constr_jsonpath_to_location(location,current_path=[])
    self.keys.each do |key|
      value = self[key]

      # puts JsonPath.new('$..location').on(value).any? {|v| v == location}
      if JsonPath.new('$..location').on(value).any? {|v| v == location}
        if value.is_a? Hash
          current_path << key
          value.constr_jsonpath_to_location(location,current_path)
        end
      end
    end
    current_path
  end
end
