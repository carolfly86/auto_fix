class TupleMutation
	def initialize(test_id,pk,type,branches,fQueryObj,tQueryObj,t_predicate_tree)
		@pk = pk
		# pp @pk
		@type = type
		@renamedPK = @pk.map do|pk| 
			newPK = Hash.new()
			newPK['col'] = (pk['col'].include?('.') ? pk['col'].split('.')[1].to_s : pk['col'] )+'_pk'
			newPK['val'] = pk['val']
			newPK
		end

		@branches=branches
		@test_id = test_id
		branchNames = @branches.map{|br| "'#{br.name}'"}.join(',')
		@branchCond="t.branch_name in (#{branchNames})"
		@mutation_tbl='mutation_tuple'

		@fParseTree = fQueryObj.parseTree
		# @f_result_tbl=fQueryObj.table
		f_fromPT = @fParseTree['SELECT']['fromClause']
		tWherePT = tQueryObj.parseTree['SELECT']['whereClause']
		# t_fromPT = tQueryObj.parseTree['SELECT']['fromClause']

		@pkCond=QueryBuilder.pkCondConstr(@pk)
		@pkCol = QueryBuilder.pkColConstr(@pk)
		@pkJoin=QueryBuilder.pkJoinConstr(@pk)
		@pkVal= QueryBuilder.pkValConstr(@pk)

		@renamePKCond = QueryBuilder.pkCondConstr(@renamedPK)
		@renamedPKCol = QueryBuilder.pkValWithColConstr(@renamedPK)

		@pkCond_strip_tbl_alias = QueryBuilder.pkCondConstr_strip_tbl_alias(@pk)

		allcolumns_construct(f_fromPT)

		constraint_construct(t_predicate_tree, tWherePT)

	end

	def constraint_construct(t_predicate_tree, tWherePT)

		@constraintColumnList= t_predicate_tree.all_columns
		# pp 't_predicate_tree.all_columns'
		# pp t_predicate_tree.all_columns
		@constraintPredicateQuery=ReverseParseTree.whereClauseConst(tWherePT)
		# pp @constraintPredicateQuery
		@constraintPredicateQuery=rewrite_predicate_query(@constraintPredicateQuery, @constraintColumnList)

		# pp '@constraintPredicateQuery'
		# puts @constraintPredicateQuery
		@excluded_query = %Q(
				(select mutation_branches,mutation_nodes,mutation_cols
				FROM #{@mutation_tbl}
				where mutation_branches <> 'none' and mutation_nodes <>'none' and mutation_cols <>'none' )
				except (#{@constraintPredicateQuery}))
	end
	# def predicate_construct
		# # get the failed predicates related the error in this pk
		# query ="select distinct t.branch_name,n.node_name,query,columns,suspicious_score "+
		# 		"from node_query_mapping n join tuple_node_test_result t "+
		# 		"on t.node_name=n.node_name and t.test_id = n.test_id "+
		# 		"where t.test_id = #{@test_id} and n.type='f' and #{@pkCond_strip_tbl_alias} "+ (branchNames.empty? ? '': " and #{@branchCond}")
		# @predicateList =PredicateUtil.get_predicateList(query)

		# # pp "@constraintPredicateList: #{@constraintPredicateList}"
		# @columnList=Array.new()
		# @columnList=PredicateUtil.get_predicateColumns(@predicateList).uniq{ |c| c.colname+c.relname }

		# remove pk from columnlist
		# @pkCol.split(',').each do |pkcol|
		# 	@columnList.select!{|col| col.colname != pkcol.delete(' ') }
		# end

		# @columns=PredicateUtil.column_str_constr(@columnList)
		# @columnList.delete(@pkCol)


		# pp @allColumns
		# mutationTbl_create()
		# @predicateQuery=PredicateUtil.get_predicateQuery(@predicateList)
		# @predicateQuery = rewrite_predicate_query(@predicateQuery)
	# end
	def allcolumns_construct(f_fromPT)
		@allColumnList = DBConn.getAllRelFieldList(f_fromPT)
		# pp @allColumnList
		@all_column_combinations = []
		# columnNames = @allColumnList.map do |field|
		# 	# field.colname
		# 	"#{field.relname}_#{field.colname}"
		# end
		max = @allColumnList.count()
		1.upto(max) do |i|
			@allColumnList.combination(i).each do |cc|
				@all_column_combinations << cc.to_set
			end
		end
        # pp '@all_column_combinations'
        # pp @all_column_combinations.count()
		# pp @allColumnList
		@allColumns = @allColumnList.map do |field|
			col = field.relname.nil? ? "#{field.relname}.#{field.colname}" : "#{field.relalias}.#{field.colname}"
			"#{col} as #{field.relname}_#{field.colname} "
		end.join(',')
		@allColNames = @allColumnList.map do |field|
			"#{field.relname}_#{field.colname} "
		end.join(',')
	end
	#unwanted to satisfied mutation
	def unwanted_to_satisfied()
		# t_pkCol=@pkCol.split(',').map{|c| "t.#{c}"}.join(',')
		found = false
		@remaining_cols=@all_column_combinations.clone
		updateTup = get_first_satisfiedPK()
		nodes = @branches[0].nodes.map{|nd| nd.name }
		max = nodes.count()

		1.upto(max) do |i|
			bn_pair = unwanted_branch_node_pairs(i)
			mutationTbl_upd(bn_pair,updateTup)
			# pp @excluded_query
			exluded=DBConn.exec(@excluded_query)
			nd_combinations_set = nodes.combination(i).map{|nd| nd.to_set}.to_set
			if exluded.count() < nd_combinations_set.count
				found = true
				exluded_nodes=[]
				exluded.each do |e|
					if i == 1
						ex_nd = Hash.new()
						ex_nd['branch_name'] = @branches[0].name
						ex_nd['node_name'] = e['mutation_nodes']
						exluded_nodes << ex_nd
					else
						# pp e['mutation_nodes']
						# e['mutation_nodes'].split(',').each do |nds|
							# delete satisfied combination set, remaining is excluded combination set
						nd_combinations_set.delete(e['mutation_nodes'].split(',').to_set)
						# end
						# pp 'nd_combinations_set'
						# pp nd_combinations_set
						# nodes which are not in excluded combinations will be exonerated
						(nodes - nd_combinations_set.flatten.to_a).each do |nd|
							ex_nd = Hash.new()
							ex_nd['branch_name'] = @branches[0].name
							ex_nd['node_name'] = nd
							exluded_nodes << ex_nd
						end
					end
				end
				# pp "nodes to be exonerated"
				# pp exluded_nodes
				exnorate_nodes(exluded_nodes)
				return
			end
		end
		# if not able to find suspicious node
		# it might be due to missing node on some column combinations
		unless found
			puts 'fail to find in existing branches. Trying column combinations'
			exnorate_all_nodes(@branches[0].name)
			max = @remaining_cols.map{|cols| cols.count}.max
			1.upto(max) do |i|
				ith_col_combinations = @remaining_cols.select{|cols| cols.count == i }
				# the ith combination is the the number of guilty branches
				bn_pair = remaining_col_combination_bn_pairs(ith_col_combinations)
				# mutationTbl_create()
				mutationTbl_upd(bn_pair,updateTup)
				satisfied=DBConn.exec(@constraintPredicateQuery)
				if satisfied.count() >0
					# 1.upto(i) do |j|
					blm_nodes = []
					nd = Hash.new()
					nd['branch_name'] = @branches[0].name
					nd['node_name'] = "missing_node#{i}"
					nd['columns'] = "{#{satisfied.map{|e| e['mutation_cols']}.join(',')}}"
					nd['query'] =''
					nd['location'] = 0
					nd['type'] = 'f'
					blm_nodes <<nd
					blame_nodes(blm_nodes)
					# end
					found = true
					return
				end
			end
		end
		unless found
			abort('Fail to find the error')
		end
	end

	#missing to excluded mutation
	def missing_to_excluded()

		# f_pkCol=@pkCol.split(',').map{|c| "#{c}"}.join(',')
		# target_tuple=find_target_tuple(@pkCond)
		# exluded_pk=get_exludedPKList()
		found = false
		@remaining_cols=@all_column_combinations.clone
		max = @branches.count()
		updateTup = get_first_exludedPK()
		1.upto(max) do |i|
			bn_pair = missing_branch_node_pairs(i)
			# mutationTbl_create()
			mutationTbl_upd(bn_pair,updateTup)

			# pp @constraintPredicateQuery
			# if @pk.any?{|pk| pk['col'] = 'emp_no' and pk['val'] = '58160'}
			# 	abort('investigate')
			# end
			satisfied=DBConn.exec(@constraintPredicateQuery)
			if satisfied.count() >0
				uniq_branches = satisfied.to_a.uniq{|s| s['mutation_branches']}
				if uniq_branches.count < @branches.combination(i).count
					found = true
					satisfied_branches = uniq_branches.map do |s|
						if i == 1
							"'#{s['mutation_branches']}'"
						else
							s['mutation_branches'].split(',').uniq.map{|b| "'#{b}'"}.join(',')
						end
					end.join(',')
					query = "select branch_name,node_name from tuple_node_test_result where #{@pkCond_strip_tbl_alias} and branch_name in (#{satisfied_branches})"
					satisfied_nodes = DBConn.exec(query)
					exnorate_nodes(satisfied_nodes)
					return
				end
			end
		end
		# if not able to find suspicious branch
		# it might be due to missing branch on some column combinations
		unless found
			puts 'fail to find in existing branches. Trying column combinations'
			exnorate_all_nodes
			max = @remaining_cols.map{|cols| cols.count}.max
			1.upto(max) do |i|
				ith_col_combinations = @remaining_cols.select{|cols| cols.count == i }
				# puts "#{i} combination"
				# pp @remaining_cols.count
				# puts '-----------------------'
				# the ith combination is the the number of guilty branches
				bn_pair = remaining_col_combination_bn_pairs(ith_col_combinations)
				# mutationTbl_create()
				mutationTbl_upd(bn_pair,updateTup)
				excluded=DBConn.exec(@excluded_query)
				if excluded.count() >0
					1.upto(i) do |j|
						nodes = []
						nd = Hash.new()

						nd['branch_name'] = "missing_branch#{i}"
						nd['node_name'] = "missing_node#{i}"
						nd['columns'] = "{#{excluded.map{|e| e['mutation_cols']}.join(',')}}"
						nd['query'] =''
						nd['location'] = 0
						nd['type'] = 'f'
						nodes <<nd
						blame_nodes(nodes)
					end

					found = true
					return
				end
			end
		end
		unless found
			abort('Fail to find the error')
		end
	end

	def mutate_to_satisfied_tuple()
		res = DBConn.exec(@constraintPredicateQuery)
	end


	# excluded pk is in the table
	# but not in t_restul or f_result
	# def get_exludedPKList()
	# 	pkCol=@pk.map{|c| "#{c['col']}"}.join(',')
	# 	whereCond='1=1'
	# 	allPKQuery =  ReverseParseTree.reverseAndreplace(@fParseTree, pkCol,whereCond)
	# 	allPKQuery = "WITH allPK as (#{allPKQuery})"

	# 	pkCoalesce = @pk.map{|c| "COALESCE(f.#{c['col']},t.#{c['col']}) as #{c['col']}"}.join(',')
	# 	resultPKQuery = "resultPK as (SELECT #{pkCoalesce} FROM #{@f_result_tbl} f FULL JOIN t_result t on #{@pkJoin})"
	# 	pkCol=@pk.map{|c| "a.#{c['col']}"}.join(',')
	# 	pkJoin = @pkJoin.gsub('f.','a.').gsub('t.','r.')
	# 	pkCond = @pk.map{|c| "r.#{c['col']} is null"}.join(' and ')
	# 	query = %Q(#{allPKQuery}, 
	# 			#{resultPKQuery}
	# 			SELECT #{pkCol} from
	# 			allPK a LEFT JOIN resultPK r 
	# 			ON #{pkJoin}
	# 			where #{pkCond}
	# 			)
	# 	DBConn.exec(query)
	# end

	# excluded pk is in the table
	# but not in t_restul or f_result
	# this function return the first excluded pk with the different value in predicateColumn
	def get_first_exludedPK()

		allColumns = @allColumnList.map do |field|
			"#{field.colname} as #{field.relname}_#{field.colname} "
		end.join(',')
		query = "select #{allColumns} from golden_record where type = 'excluded';"
		# pp query
		res = DBConn.exec(query)
	end
	# excluded pk is in the table
	# but not in t_restul or f_result
	# this function return the first excluded pk with the different value in predicateColumn
	def get_first_satisfiedPK()
		allColumns = @allColumnList.map do |field|
			"#{field.colname} as #{field.relname}_#{field.colname} "
		end.join(',')
		query = "select #{allColumns} from golden_record where type = 'satisfied' and branch = '#{@branches[0].name}';"
		res = DBConn.exec(query)
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
	# def find_target_tuple(whereClauseReplacement)
	# 	targetListReplacement ="#{@pkCol},#{@columns}"
	# 	query =  ReverseParseTree.reverseAndreplace(@fParseTree, targetListReplacement,whereClauseReplacement)
	# 	# puts 'find_target_tuple'
	# 	# puts query
	# 	DBConn.exec(query)
	# end
	def rewrite_predicate_query(query, column_list)
		# pp column_list
		column_list.each do |col|
			# remove table alias
			query=RewriteQuery.replace_fullname_with_colname(query,col)

			# replace colname with colalias
			# query=RewriteQuery.replace_colname_with_colalias(query,col)
			query=RewriteQuery.replace_colname_with_renamed_colname(query,col)
		end
		# puts 'rewrite_predicate_query'
		# pp query
		query="SELECT mutation_branches,mutation_nodes, mutation_cols FROM #{@mutation_tbl} WHERE mutation_branches <> 'none' and mutation_cols <>'none' and "+query

		# query="SELECT count(1) FROM #{@mutation_tbl} WHERE "+query

	end
	def mutationTbl_create()
		# colCombination = @allColumnList.combination(ith_combination).to_a.map{|c| c.map{|col| col.colname}.join(',')}.map{|c| "'#{c}'"}.join(',')

		renamedPKCol = @pk.map{|pk|  "#{pk['col']} as #{pk['alias']}_pk" }.join(', ')
		targetListReplacement ="#{renamedPKCol},'none'::varchar(300) as mutation_branches,'none'::varchar(300) as mutation_nodes,'none'::varchar(300) as mutation_cols,#{@allColumns}"
		query =  ReverseParseTree.reverseAndreplace(@fParseTree, targetListReplacement,@pkCond)
		pkList = @renamedPK.map{|pk| pk['col']}.join(', ')+',mutation_branches,mutation_cols'
		query=QueryBuilder.create_tbl(@mutation_tbl,pkList,query)
		# puts 'mutationTbl_create'
		# puts query
		# create
		DBConn.exec(query)

	end
	def mutationTbl_upd(bn_pairs,updateTup)

		mutationTbl_create()

		updQueryArray = []
		renamedPKCond = @pk.map{|pk|  pk['col']+'_pk' +' = '+ pk['val'].to_s.str_int_rep }.join(' AND ')

		query = "select #{@allColNames} from #{@mutation_tbl} where #{@renamePKCond} and mutation_branches = 'none' and mutation_cols = 'none'"
		res = DBConn.exec(query)
		original_tup =res[0]

		#insert
		query = ""
		bn_pairs.each_with_index do |bn,id|
			insert_tup=  original_tup.map do |key,original_value|

				# # bn['cols'].split(',').each do |col|
				# pp bn
				# binding.pry
				# pp bn['cols']
				if bn['cols'].to_a.any?{|col| key == "#{col.relname}_#{col.colname}" }
					# pp 'replace'
					# pp key
					# pp original_value
					# pp updateTup[0][key]
					"#{updateTup[0][key].to_s.str_int_rep} as #{key}"
				else
					# pp 'nonreplace'
					# pp key
					"#{original_value.to_s.str_int_rep} as #{key} "
				end
				# end
			end.join(',')
			mutation_columns = bn['cols'].to_a.map{|c| c.fullname}.join(',')
			query = query + "INSERT INTO #{@mutation_tbl} select #{@renamedPKCol},'#{bn['branches']}' as mutation_branches,'#{bn['nodes']}' as mutation_nodes, '#{mutation_columns}' as mutation_cols ,#{insert_tup} ;"
		end
		# if @pk.any?{|pk| pk['col'] = 'emp_no' and pk['val'] = '58160'}
		# 	pp bn_pairs
		# end
		DBConn.exec(query)

	end
	def remaining_col_combination_bn_pairs(ith_col_combinations)
		bn_pairs = []
		ith_col_combinations.each do |cols|
			# pp cols
			bn= Hash.new()
			bn['branches'] = 'missing_branch'
			bn['nodes']='missing_node'
			bn['cols'] = cols
			bn_pairs << bn
		end
		bn_pairs
	end
	def missing_branch_node_pairs(ith_combination)
		bn_pairs = []
		@branches.combination(ith_combination).each do |br_comb|
			bn= Hash.new()
			bn['branches'] = br_comb.map{|br| br.name}.join(',')
			bn['nodes'] = ''
			bn['cols'] = Set.new()
			br_comb.each_with_index do |br,idx|
				# pp @pkCond_strip_tbl_alias
				# only need to find passed_node if it's on single branch
				passed_nodes = ith_combination == 1 ? br.passed_nodes(@pkCond_strip_tbl_alias,@test_id,@type) : []
				# pp passed_nodes
				if passed_nodes.count() > 0
					node = passed_nodes[0]
					# cols_strip_relalias = node.columns.map {|c| c.strip_relalias}
					# colnames = node.columns {|c| c.colname }.join(',')
					bn['nodes'] = node.name
					# @remaining_cols.delete(cols_strip_relalias.to_set)
					column_set = node.columns.to_set
					bn['cols']= column_set
					# bn['cols'] = bn['cols'] + ( idx >0 ? "," : "") + "#{cols_strip_relalias.join(',')}"
					@remaining_cols.delete(column_set)
				else
					if ith_combination == 1
						br.nodes.each do |nd|
							bn1= Hash.new()
							bn1['branches'] = bn['branches']
							bn1['nodes']=nd.name
							# bn1['cols'] = "#{nd.columns.join(',')}"
							column_set = nd.columns.to_set
							bn1['cols'] = column_set
							@remaining_cols.delete(column_set)

							bn_pairs << bn1
						end
					else
						node = br.nodes[0]
						bn['nodes']=node.name
						# cols_strip_relalias = node.columns.map {|c| c.strip_relalias}
						# @remaining_cols.delete(cols_strip_relalias.to_set)
						# bn['cols'] = bn['cols'] + ( idx >0 ? "," : "") + "#{cols_strip_relalias.join(',')}"	
						column_set = node.columns.to_set
						@remaining_cols.delete(column_set)
						bn['cols']= column_set
					end
				end
			end
			bn_pairs << bn if bn['cols'].count() > 0

		end
		bn_pairs
	end
	def unwanted_branch_node_pairs(ith_combination)
		bn_pairs = []
		# puts "#{ith_combination} ith_combination"

		@branches.each do |br|
			# max = br.nodes.count()
			# 1.upto(max) do |i|
			br.nodes.combination(ith_combination).each do |nd_comb|
				cols = Set.new()
				bn= Hash.new()
				bn['branches'] = br.name
				bn['nodes']=''
				bn['cols'] = Set.new()
				nd_comb.each_with_index do |nd,idx|
					bn['nodes'] = bn['nodes']+ ( idx >0 ? "," : "") + "#{nd.name}"
					# cols_strip_relalias = nd.columns.map {|c| c.strip_relalias}
					colnames = nd.columns.map {|c| c.colname}
					# bn['cols'] = bn['cols']+ ( idx >0 ? "," : "") + "#{cols_strip_relalias.join(',')}"
					column_set = nd.columns.to_set
					# pp 'column_set'
					# pp column_set
					bn['cols'].merge(column_set)
					@remaining_cols.delete(column_set)
					# cols.merge(nd.columns)
				end
				bn_pairs << bn
			end
			# end
		end
		# pp bn_pairs

		bn_pairs
	end

	def exnorate_nodes(nodes)
		# puts 'exonerating'

		nodes.each do |nd|
			# pp nd
			branch_node_cond=" branch_name = '#{nd['branch_name']}' and node_name = '#{nd['node_name']}'"
			query ="UPDATE node_query_mapping"+
			      " SET suspicious_score = suspicious_score -1 "+
				  "where test_id = #{@test_id} and type='f' and suspicious_score >0"+ 
				  "and #{branch_node_cond}"
			# pp query
			DBConn.exec(query)
		end

	end
	def exnorate_all_nodes(branch = '')
		query ="UPDATE node_query_mapping "+
		      "SET suspicious_score = suspicious_score - 1 "+
			  "where test_id = #{@test_id} and type = 'f' and suspicious_score >0 and branch_name not like 'missing%' and node_name not like 'missing%'"+
			  (branch =='' ? '' : " and branch_name = '#{branch}'")
		# pp query
		DBConn.exec(query)
	end
	def blame_nodes(nodes)

		nodes.each do |nd|
			branch_node_cond=" branch_name = '#{nd['branch_name']}' and node_name = '#{nd['node_name']}'"
			query ="UPDATE node_query_mapping"+
			      " SET suspicious_score = suspicious_score + 1 "+
				  "where test_id = #{@test_id} and type='f' "+ 
				  "and #{branch_node_cond}"
			# pp query
			res = DBConn.exec(query)
			if res.cmd_tuples()==0
				insert_query = 'INSERT INTO node_query_mapping '
				select_query = nodes.map do |nd|
					%Q(select #{@test_id} as test_id, 
					'#{nd['branch_name']}' as branch_name,
					'#{nd['node_name']}' as node_name, 
					'#{nd['query']}' as query, 
					'#{nd['location']}' as location, 
					'#{nd['columns']}' as columns, 
					1 as suspicious_score, 
					'#{nd['type']}' as type)
				end.join(' UNION ')
				query = insert_query+select_query
				# pp query
				res = DBConn.exec(query)
			end
		end
	end

end