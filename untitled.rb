   def find_location(tree, locVal)
    puts 'tree'
   	puts tree
    keys = []
    keys = tree.keys
    result = []
    keys.each do |key|
      value = tree[key]
      puts "key: #{key}"
      puts 'value: '
      pp value
      if key == 'location'
        puts "locVal: #{locVal}"
        if tree[key].to_s == locVal
          puts 'insert tree'
          puts tree
          result << tree 
        end
      else
        if value.is_a? Array
          value.each do |v|
            result << find_location(value,locVal) if value.is_a? Hash
          end
        else
          result << find_location(value,locVal) if value.is_a? Hash  
        end
        
      end
    end
    result.flatten
  end



E82XNxSP