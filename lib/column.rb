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
end 