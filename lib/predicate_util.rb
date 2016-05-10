module PredicateUtil
	def PredicateUtil.get_predicateList(query)
		# pp query
		res=DBConn.exec(query)

		pcList = Array.new()
		num_fields=res.num_fields()
		res.each do |r|
			colsList=[]
			r['columns'].to_s.gsub(/[\{\}]/,'').split(',').each do |c|
				col=c.split('.')
				column=Column.new
				if col.count()>0
					column.relalias = col[0]
					column.colname = col[1]
					column.relname=''
				else
					column.colname=col[0]
					column.relname=''
					column.relalias=''
				end

				colsList<<column
			end
			r['columns']=colsList
			pcList<<r
		end
		pcList

	end
	def PredicateUtil.get_predicateQuery(predicateList, type)
		logicOpr = type=='U' ? 'AND' : 'OR'
		predicateQuery=''
		predicateList.each do |p|
			# columnList += p['columns']
			predicateQuery << p['query'] +" #{logicOpr} "
			# p['columns'].each do |c|
			# 	predicateQuery =predicateQuery.gsub(c['expr'],c['column'])
			# end
			# predicateQuery = remove_tbl_alias_in_predicates(predicateQuery,p['columns'])
		end
		predicateQuery=predicateQuery.chomp("#{logicOpr} ") if predicateQuery.end_with?("#{logicOpr} ")
		return predicateQuery
	end
	def PredicateUtil.get_predicateColumns(predicateList)
		columnList=Array.new()
		predicateList.each do |p|
			columnList += p['columns']
		end
		columnList.uniq
	end


	def PredicateUtil.column_str_constr(columnList)
		columnList.map do |c| 
			c.expr
		end.join(',')
	end
end