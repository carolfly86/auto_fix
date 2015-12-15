class Column
	attr_accessor :colname, :relname, :relalias, :datatype, :typcategory

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
		#pp @ps
	end


	def == (other)
		if other.class == self.class
		    @relname  == other.relname and @colname == other.colname
		else
		    false
		end
		#pp @ps
	end
end 