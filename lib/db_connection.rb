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
            fields << relAlias.nil? ? relName : relAlias['ALIAS']['aliasname']
            fields << c['column_name']
            fieldsList << fields
          end
    	end 

    	return fieldsList.compact
    	#pp fieldsList
 	  end


      # Find all the relations(tbls) from FROM Clause including their columns
    def DBConn.getAllRelFieldList(fromPT)
      relNames = JsonPath.on(fromPT.to_json, '$..RANGEVAR')
      fieldsList = []
      relNames.each do |r|
          rel = Hash.new()
          relName = r['relname'] 
          relAlias = r['alias']
          #numericDataTypes = ['smallint','integer','bigint','decimal','numeric','real','double precision','serial','bigserial']
          query = QueryBuilder.find_cols_by_data_typcategory(relName, '','')
          colList=  exec(query).to_a
          colList.each do |c|
            field = Column.new
            field.colname = c['column_name']
            field.relname = relName 
            field.relalias = relAlias.nil? ? relName : relAlias['ALIAS']['aliasname']
            field.datatype = c['data_type']
            field.typcategory = c['typcategory']
            # field = {}

            # field['rel_alias'] = relAlias.nil? ? relName : relAlias['ALIAS']['aliasname']
            # field['rel_name'] = relName  
            # field['column_name'] = c['column_name']
            # field['data_type'] = c['data_type']
            # field['typcategory'] = c['typcategory']
            fieldsList << field
          end
      end 

      return fieldsList.compact
      #pp fieldsList
    end
    def DBConn.getColByDataCategory(tbl,category,col)
      query = QueryBuilder.find_cols_by_data_typcategory(tbl, category, col)
      colList=  exec(query).to_a
      fieldsList = []
      colList.each do |c|
        field = {}
        field['column_name'] = c['column_name']
        field['data_type'] = c['data_type']
        field['typcategory'] = c['typcategory']
        fieldsList << field
      end
    end
end
