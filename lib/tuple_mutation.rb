class TupleMutation
	def initialize(test_id,pk,type,branch,fParseTree,tWherePT)
		@pk = pk
		@branch=branch
		@test_id = test_id
		@branchCond="branch_root = '#{@branch['branch_root']}'"
		@mutation_tbl='mutation_tuple'

		@fParseTree = fParseTree
		@tWherePT = tWherePT

		@pkCond=QueryBuilder.pkCondConstr(@pk)
		@pkCol = QueryBuilder.pkColConstr(@pk)
		@pkJoin=QueryBuilder.pkJoinConstr(@pk)
		@pkVal= QueryBuilder.pkValConstr(@pk)

		query ="select n.node_name,query,columns,suspicious_score "+
				"from node_query_mapping n join tuple_node_test_result t "+
				"on t.node_name=n.node_name and t.test_id = n.test_id "+
				"where t.test_id = #{@test_id} and n.type='f' and #{@pkCond} "+ (@branch.empty? ? '': " and #{@branchCond}")
		@predicateList =PredicateUtil.get_predicateList(query)


		query ="select query,columns,suspicious_score "+
				"from node_query_mapping "+
				"where test_id = #{@test_id} and type='t'"

		@constraintPredicateList = PredicateUtil.get_predicateList(query)


		@columnList=Array.new()
		@constraintColumnList=Array.new()
		@columnList=PredicateUtil.get_predicateColumns(@predicateList)
		# remove pk from columnlist
		@pkCol.split(',').each do |pkcol|
			@columnList.select!{|col| col['column'] != pkcol }
		end
		@columns=PredicateUtil.column_str_constr(@columnList)

		# @columnList.delete(@pkCol)



		@predicateQuery=PredicateUtil.get_predicateQuery(@predicateList,type)
		@predicateQuery="SELECT count(1) FROM #{@mutation_tbl} WHERE "+@predicateQuery
		@constraintColumnList=PredicateUtil.get_predicateColumns(@constraintPredicateList)
		# remove pk from constraintColumnList
		@pkCol.split(',').each do |pkcol|
			@constraintColumnList.select!{|col| col['column'] != pkcol }
		end


		@constraintPredicateQuery=ReverseParseTree.whereClauseConst(tWherePT)
		@constraintPredicateQuery = PredicateUtil.remove_tbl_alias_in_predicates(@constraintPredicateQuery,@constraintColumnList)
		@constraintPredicateQuery = "SELECT count(1) FROM #{@mutation_tbl} WHERE "+@constraintPredicateQuery

		@allColumnList=(@columnList+@constraintColumnList).uniq
		@allColumns=PredicateUtil.column_str_constr(@allColumnList)

		mutationTbl_create()

		# curNode = Tree::TreeNode.new(nodeName, '')    
	end

	#unwanted to satisfied mutation
	def unwanted_to_satisfied()
		t_pkCol=@pkCol.split(',').map{|c| "t.#{c}"}.join(',')
		target_tuple=find_target_tuple(@pkCond)
		satisfied_pk_query="select #{t_pkCol} from t_result t join f_result f on #{@pkJoin}"
		satisfied_pk=DBConn.exec(satisfied_pk_query)
		max = @predicateList.count()
		1.upto(max) do |i|
			@predicateList.combination(i).each do |p|
				if p.count()>1
					p 'do nothing'
				else
					predicateColumnList = p[0]['columns']
					satisfied_pk.each do |spk|
						h=Hash.new()
						hList= Array.new()
						spk.each_pair do |k,v| 
							h['col']=k
							h['val']=v
							hList<<h
						end	

						cond=QueryBuilder.pkCondConstr(hList)
						satisfied_tuple=find_target_tuple(cond)
						# newTuple= Hash.new()
						updQuery=''
						predicateColumnList.each do |pc|
							col=pc['column']
							val=satisfied_tuple[0][col].to_s.str_int_rep
							updQuery= "#{col}=#{val}"
							# newTuple[colName]=satisfied_tuple[0][colName]
						end
						mutationTbl_upd(updQuery)
						# pp newTuple
						if is_satisfied?()
							suspicious_socore_upd(p)
							return
						end
					end
				end
			end
		end

	end

	#missing to excluded mutation
	def missing_to_excluded()
		f_pkCol=@pkCol.split(',').map{|c| "#{c}"}.join(',')
		target_tuple=find_target_tuple(@pkCond)
		exluded_pk=get_exludedPKList()
		max = @predicateList.count()
		1.upto(max) do |i|
			@predicateList.combination(i).each do |p|
				if p.count()>1
					p 'do nothing'
				else
					predicateColumnList = p[0]['columns']
					exluded_pk.each do |epk|
						h=Hash.new()
						hList= Array.new()
						epk.each_pair do |k,v| 
							h['col']=k
							h['val']=v
							hList<<h
						end	

						cond=QueryBuilder.pkCondConstr(hList)
						exluded_tuple=find_target_tuple(cond)
						# newTuple= Hash.new()
						updQuery=''
						predicateColumnList.each do |pc|
							col=pc['column']
							val=exluded_tuple[0][col].to_s.str_int_rep
							updQuery= "#{col}=#{val}"
							# newTuple[colName]=satisfied_tuple[0][colName]
						end
						mutationTbl_upd(updQuery)
						# pp newTuple
						if is_excluded?()
							# p 'Found!'
							suspicious_socore_upd(p)
							return
						end
					end
				end
			end
		end		
	end
	def get_exludedPKList()
		pkCol=@pk.map{|c| "#{c['col']}"}.join(',')
		whereCond='1=1'
		allPKQuery =  ReverseParseTree.reverseAndreplace(@fParseTree, pkCol,whereCond)
		allPKQuery = "WITH allPK as (#{allPKQuery})"

		pkCoalesce = @pk.map{|c| "COALESCE(f.#{c['col']},t.#{c['col']}) as #{c['col']}"}.join(',')
		resultPKQuery = "resultPK as (SELECT #{pkCoalesce} FROM f_result f FULL JOIN t_result t on #{@pkJoin})"
		
		pkCol=@pk.map{|c| "a.#{c['col']}"}.join(',')
		pkJoin = @pkJoin.gsub('f.','a.').gsub('t.','r.')
		pkCond = @pk.map{|c| "r.#{c['col']} is null"}.join(',')
		query = %Q(#{allPKQuery}, 
				#{resultPKQuery}
				SELECT #{pkCol} from
				allPK a LEFT JOIN resultPK r 
				ON #{pkJoin}
				where #{pkCond}
				)
		# pp query
		DBConn.exec(query)
	end
	def is_satisfied?()
		included=returned_by_query?(@predicateQuery)
		satisfied=returned_by_query?(@constraintPredicateQuery)
		# binding.pry
		return (included and satisfied)
	end
	def is_unwanted?()
		included=returned_by_query?(@predicateQuery)
		satisfied=returned_by_query?(@constraintPredicateQuery)
		# binding.pry
		return (included and (not satisfied))
	end
	def is_missing?()
		included=returned_by_query?(@predicateQuery)
		satisfied=returned_by_query?(@constraintPredicateQuery)
		# binding.pry
		return ((not included) and  satisfied)
	end
	def is_excluded?()
		included=returned_by_query?(@predicateQuery)
		satisfied=returned_by_query?(@constraintPredicateQuery)
		# binding.pry
		return ((not included) and  (not satisfied))
	end

	def returned_by_query?(query)
		res=DBConn.exec(query)
		return res[0]['count'].to_i>0
	end
 

	def find_target_tuple(whereClauseReplacement)
		targetListReplacement ="#{@pkCol},#{@columns}"
		query =  ReverseParseTree.reverseAndreplace(@fParseTree, targetListReplacement,whereClauseReplacement)
		DBConn.exec(query)
	end
	
	def mutationTbl_create()
		targetListReplacement ="#{@pkCol},#{@allColumns}"
		query =  ReverseParseTree.reverseAndreplace(@fParseTree, targetListReplacement,@pkCond)
		query=QueryBuilder.create_tbl(@mutation_tbl,'',query)
		DBConn.exec(query)
	end
	# def mutationTbl_insert(cols,values)
	# 	query =  "INSERT INTO #{@mutation_tbl} (#{cols}) values (#{values})"
	# 	pp query
	# 	DBConn.exec(query)
	# end
	def mutationTbl_upd(setQuery)
		query = "UPDATE #{@mutation_tbl} SET #{setQuery} where #{@pkCond}"
		# pp query
		DBConn.exec(query)
	end

	def suspicious_socore_upd(nodes)
		nodeNames=nodes.map{|n| "'"+n['node_name']+"'"}.join(',')
		query ="UPDATE node_query_mapping as n"+
		      " SET suspicious_score = suspicious_score -1 "+
		      "from tuple_node_test_result as t "+
			  "where t.test_id = n.test_id and t.node_name=n.node_name and n.type='f' and #{@pkCond} "+ 
			  "and t.test_id = #{@test_id} and t.node_name not in (#{nodeNames})"
			  (@branch.empty? ? '': " and #{@branchCond}")
		# pp query
		DBConn.exec(query)

	end
end