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
				cols=Hash.new()
				if col.count()>0
					cols['table_alias']=col[0]
					cols['column']=col[1]
					cols['expr']=c
				else
					cols['table_alias']=''
					cols['column']=col[1]
					cols['expr']=c
				end
				colsList<<cols
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
			predicateQuery = remove_tbl_alias_in_predicates(predicateQuery,p['columns'])
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

	def PredicateUtil.remove_tbl_alias_in_predicates(predicateQuery,columns)
		columns.each do |c|
			predicateQuery =predicateQuery.gsub(c['expr'],c['column'])
		end
		predicateQuery
	end
	def PredicateUtil.column_str_constr(columnList)
		columnList.map do |c| 
				c['expr']
		end.join(',')
	end
end