module DBConn
	@cfg = YAML.load_file( File.join(File.dirname(__FILE__), "../config/default.yml") )
	@conn = PG::Connection.open(dbname: @cfg['default']['database'], user: @cfg['default']['user'], password: @cfg['default']['password'])

	def DBConn.exec(query)
		@conn.exec(query)  
	end

	# Find all the relations(tbls) from FROM Clause including their columns
  	def DBConn.fromRels(fromPT)
    	relNames = JsonPath.on(fromPT.to_json, '$..relname')
    	relList = []
    	relNames.uniq.each do |r|
      		rel = Hash.new()
      		rel['relName'] = r 
      		query = QueryBuilder.find_all_cols(r)
      		rel['colList'] =  exec(query).to_a
      		relList << rel
    	end 
    	relList.compact!
    	pp relList
 	end
end
