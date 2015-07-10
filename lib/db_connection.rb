module DBConn
	@cfg = YAML.load_file( File.join(File.dirname(__FILE__), "../config/default.yml") )
	@conn = PG::Connection.open(dbname: @cfg['default']['database'], user: @cfg['default']['user'], password: @cfg['default']['password'])

	def DBConn.exec(query)
		@conn.exec(query)  
	end

	# Find all the relations(tbls) from FROM Clause including their columns
  	def DBConn.getRelFieldList(fromPT)
    	relNames = JsonPath.on(fromPT.to_json, '$..RANGEVAR')
    	fieldsList = []
    	relNames.each do |r|
      		rel = Hash.new()
      		relName = r['relname'] 
          relAlias = r['alias']
          numericDataTypes = ['smallint','integer','bigint','decimal','numeric','real','double precision','serial','bigserial']
      		query = QueryBuilder.find_cols_by_data_type(relName, numericDataTypes)
      		colList=  exec(query).to_a
      		colList.each do |c|
            fields = []
            fields << ( relAlias.nil? ? relName : relAlias['ALIAS']['aliasname'] )
            fields << c['column_name']
            fieldsList << fields
          end
    	end 

    	return fieldsList.compact
    	#pp fieldsList
 	  end
end
