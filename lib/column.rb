class Column
	attr_accessor :colname, :relname, :relalias, :datatype, :typcategory, :colalias
	attr_reader :fullname, :expr
	def fullname
		# relalias.colname
		@fullname = @relalias.to_s.empty? ? @colname : "#{@relalias}.#{@colname}" 
		# @expr = @colalias.to_s.empty? ? @expr : "#{@expr} as #{@colalias}"
	end
	def expr
		# relalias.colname
		@expr = @colalias.to_s.empty? ? self.fullname : "#{self.fullname} as #{@colalias}"
	end	
	def columnRef
		relname = relalias.nil? ? @relname : @relaias
		[relname, @colname]
	end

	def != (other)
		if other.class == self.class
		    self.columnRef != other.columnRef
		else
		    false
		end
	end

	def == (other)
		if other.class == self.class
		    @relname  == other.relname and @colname == other.colname
		else
		    false
		end
	end
    # Given a Column object
    # Find the relname the column belongs to from provided from PT
    def updateRelname(fromPT)
    	# pp fromPT
        relNames = JsonPath.on(fromPT.to_json, '$..RANGEVAR')
        # pp relNames
        # if @relalias.to_s.empty? && @relname.to_s.empty?
    	# column has no relalias or relname 
    	relNames.each do |rel|
    		tblName = rel['relname']
    		query = QueryBuilder.find_cols_by_data_typcategory(tblName,'',@colname)
    		res = DBConn.exec(query)
    		# pp res
    		if res.count()>0
    			# pp res[0]
    			@relname = tblName
    			@datatype = res[0]['data_type']
    			@typcategory = res[0]['typcategory']
    			# puts 'rel'
    			# pp rel
    			if rel.has_key?('alias') 
    				unless rel['alias'].nil?
    					@relalias = rel['alias']['ALIAS']['aliasname']
    				end
    			end
    			return
    		end
    	end
        # end
    end

end 