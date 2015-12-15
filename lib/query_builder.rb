
module QueryBuilder
	#find pk cols for tbl
	def QueryBuilder.find_pk_cols(tbl)
	    query = "SELECT a.attname, format_type(a.atttypid, a.atttypmod) AS data_type
	            FROM   pg_index i
	            JOIN   pg_attribute a ON a.attrelid = i.indrelid
	                                 AND a.attnum = ANY(i.indkey)
	            WHERE  i.indrelid = '#{tbl}'::regclass
	            AND    i.indisprimary;"
    end
    #test if tbl1 is subset of tbl2
    def QueryBuilder.subset_test(tbl1, tbl2)
    	query = 'SELECT CASE WHEN (SELECT COUNT(*) FROM ( '+tbl1+' ) as tbl1 )=0 OR (SELECT COUNT(*) FROM ( '+tbl2+' ) as tbl2 )=0'+
                           ' THEN \'EMPTYSET\''+
                           ' ELSE CASE WHEN  EXISTS ( ( '+tbl1+' ) except ( '+tbl2 +' ) )'+
                           ' THEN \'IS NOT SUBSET\' ELSE \'IS SUBSET\' END '+
                           ' END as result;'

    end
    # find matching columns in two tables
    def QueryBuilder.find_matching_cols(tbl1,tbl2)
      query = "WITH tbl1 as (select column_name, data_type FROM information_schema.columns WHERE table_name   = '#{tbl1}'),"+
              "tbl2 as (select column_name, data_type FROM information_schema.columns WHERE table_name   = '#{tbl2}')"+
              "select tbl1.column_name as col1, tbl2.column_name as col2, "+
              " CASE  WHEN tbl1.column_name = tbl2.column_name then 1 else 0 end AS is_matching "+
              " from tbl1 full outer join tbl2 on tbl1.column_name = tbl2.column_name;"
    end
    #find cols for tbl
    def QueryBuilder.find_cols_by_data_typcategory(tbl, data_type = '',col ='')
      # query = "SELECT column_name,data_type
      #         FROM information_schema.columns
      #         WHERE table_name   = '#{tbl}'" 
      puts "'#{col}'"
      query = "SELECT a.attname as column_name ,c.relname,
                pg_catalog.format_type(a.atttypid, a.atttypmod) as data_type,
                 p.typcategory
              FROM pg_catalog.pg_attribute a
              join pg_type p 
              on a.atttypid = p.oid
              join pg_catalog.pg_class c
              on a.attrelid = c.oid
              WHERE c.relname = '#{tbl}' AND a.attnum > 0 AND NOT a.attisdropped"   
      unless data_type.to_s == ''
        if data_type.kind_of?(Array)
          dataType = data_type.map{|x| "'#{x}'"}.join(',')
        else
          dataType = data_type
        end
        dataTypeCond = " AND p.typcategory IN (#{dataType}) ;"
        query = query + dataTypeCond
      end  
      unless col.to_s ==''
        colCond = " and a.attname = '#{col}'"
        query = query +colCond
      end
      query      
    end
    def QueryBuilder.create_tbl(tblName, pkList, selectQuery)
      insert = selectQuery.insert(selectQuery.downcase.index('from'), " INTO #{tblName} ")
      pkCreate = "ALTER TABLE #{tblName} ADD PRIMARY KEY (#{pkList})"
      query =  "DROP TABLE IF EXISTS #{tblName}; #{insert}; #{pkCreate};"
    end
   def QueryBuilder.satisfactionMap(tblName,fDataset,fPKList)
      query = "DROP TABLE if exists #{tblName}; "
      pkArray = fPKList.split(',')
      colsQuery = QueryBuilder.find_cols_by_data_typcategory(fDataset)
      cols = DBConn.exec(colsQuery)
      cols.each do |r|
        unless pkArray.include? r['column_name'] 
          pkArray << " 0 as #{r['column_name']} "
        end
      end
      colList = pkArray.join(',')
      query += "select #{colList} into #{tblName} from #{fDataset};"
      query += "ALTER TABLE #{tblName} ADD PRIMARY KEY (#{fPKList})"
    end

    def QueryBuilder.totalScore(tblName,pkList)
      pkArray = pkList.split(',')
      colsQuery = QueryBuilder.find_cols_by_data_typcategory(tblName)
      cols = DBConn.exec(colsQuery)
      colArray=[]
      cols.each do |r|
        unless pkArray.include? r['column_name'] 
          colArray << " sum(#{r['column_name']}) "
        end
      end
      colQuery = colArray.join('+')
      binding.pry
      query = "select ( (select #{colQuery} from #{tblName})::float/(select count(1)*#{cols.count()} from #{tblName})::float)::float as score;"
    end

end 	