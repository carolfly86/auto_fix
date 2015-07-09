
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
    #find all cols for tbl
    def QueryBuilder.find_all_cols(tbl)
      query = "SELECT column_name
              FROM information_schema.columns
              WHERE table_name   = '#{tbl}'"
    end

end 	