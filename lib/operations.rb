def queryTest(script)
	# fqueryJson = JSON.parse(File.read("sql/#{fqueryScript}.json"))
	# tqueryJson = JSON.parse(File.read('sql/true.json'))

	# fQuery = fqueryJson['query']
	# f_pkList = fqueryJson['pkList']

	# fTable = 'f_result'
	# fqueryJson['table'] = fTable
	# DBConn.tblCreation(fTable, f_pkList, fQuery)

	# tQuery = tqueryJson['query']
	# t_pkList = tqueryJson['pkList']
	# tTable = 't_result'
	# tqueryJson['table'] = tTable
	# DBConn.tblCreation(tTable, t_pkList, tQuery)


	# fqueryJson['parseTree']= PgQuery.parse(fQuery).parsetree[0]
	# tqueryJson['parseTree']=PgQuery.parse(tQuery).parsetree[0]

	# pp fqueryJson['parseTree']
	query_json = JSON.parse(File.read("sql/#{script}.json"))
	create_test_result_tbl()
	f_options_list = []
	t_options = Hash.new()
	query_json.each do |key,value|
		if key == 'F'
			value.each do |opt|
				query=opt['query']
				pk_list=opt['pkList']
				relevent = opt['relevent']
				pp relevent
				f_options = {:query=> query, :pkList =>pk_list,  :table =>'f_result', :relevent =>relevent }
				f_options_list<< f_options
			end

		elsif key == 'T'
			query=value['query']
			pk_list=value['pkList']
			t_options = {:query=> query, :pkList =>pk_list, :table =>'t_result' }
			# tqueryObj = QueryObj.new(t_options)
		end
	end
	# f_options = {:script=> fqueryScript, :table =>'f_result' }
	# fqueryObj = QueryObj.new(f_options)
	# # pp fqueryObj
	# t_options = {:script=> 'true', :table =>'t_result' }
	# tqueryObj = QueryObj.new(t_options)
	# #
	f_options_list.each_with_index do |f_options,idx|
		puts "begin test"
		beginTime = Time.now
		fqueryObj = QueryObj.new(f_options)
		tqueryObj = QueryObj.new(t_options)
		localizeErr = LozalizeError.new(fqueryObj,tqueryObj)
		selectionErrList = localizeErr.selecionErr()
		puts 'test end'
		endTime = Time.now
		m_u_tuple_count = localizeErr.missing_tuple_count + localizeErr.unwanted_tuple_count
		fqueryObj.score = localizeErr.getSuspiciouScore()
		puts 'fquery score:'
		pp fqueryObj.score
		pp fqueryObj.score['totalScore']
		duration = (endTime - beginTime).to_i
		puts "duration: #{duration}"
		update_test_result_tbl(idx,fqueryObj.query,tqueryObj.query,m_u_tuple_count,duration,fqueryObj.score['totalScore'],f_options[:relevent])
	end

	# puts "begin fix"
	# fqueryObj.score.each do |k,v|
	# 	unless k == 'totalScore'
	# 		if v.to_i >0
	# 			puts "fixing location #{k}"
	# 			hc=HillClimbingAlg.new(fqueryObj,tqueryObj)
	# 			hc.hill_climbing(k)
	# 			# hc.create_stats_tbl
	# 		end
	# 	end
	# end

end
def randomMutation(script)
	options = {:script=> script, :table =>'f_result' }
	fqueryObj = QueryObj.new(options)
	pp fqueryObj

	t_options = {:script=> 'true', :table =>'t_result' }
	tqueryObj = QueryObj.new(t_options)
	pp tqueryObj
	tqueryObj.create_stats_tbl
	return
	newQ = fqueryObj. generate_neighbor_program(127,0)

end

def create_test_result_tbl()
	query =  %Q(DROP TABLE if exists test_result;
	CREATE TABLE test_result
	(test_id int, fquery text, tquery text, m_u_tuple_count bigint, duration bigint, total_score bigint, harmonic_mean float(2), jaccard float(2));)
  	 # pp query
    DBConn.exec(query)

    query =  %Q(DROP TABLE if exists test_result_detail;
	CREATE TABLE test_result_detail
	(test_id int, branch_name varchar(30), node_name varchar(30), query text, columns text, score bigint);)
  	 # pp query
    DBConn.exec(query)
end
def update_test_result_tbl(test_id,fquery,tquery,m_u_tuple_count,duration,total_score,relevent)

	fquery = fquery.gsub("'","''")
	tquery = tquery.gsub("'","''")
	query =  %Q(INSERT INTO test_result
				select #{test_id},
				'"#{fquery}"',
				'"#{tquery}"',
				#{m_u_tuple_count},
				#{duration},
				#{total_score},
				0,
				0
			)
	# puts query
    DBConn.exec(query)

    query =  %Q(INSERT INTO test_result_detail
				select #{test_id},
				branch_name,
				node_name,
				query,
				columns,
				suspicious_score
				from node_query_mapping
				where type = 'f' and suspicious_score >0
			)
	# puts query
    DBConn.exec(query)

 	query = "select #{test_id},
				branch_name,
				node_name,
				query,
				columns,
				suspicious_score
				from node_query_mapping
				where type = 'f' and suspicious_score >0"
    res = DBConn.exec(query)
    puts 'result:'
    answer = Set.new
    res.each do |r|
    	pp r
    	predicate = "#{r['branch_name']}-#{r['node_name']}"
    	answer.add(predicate)
    end

    # update accuracy
    # pp relevent.to_a
    # binding.pry
    accuracy = Accuracy.new(answer,relevent.to_set)
    harmonic_mean = accuracy.harmonic_mean
    jaccard = accuracy.jaccard

    query = "update test_result set harmonic_mean = #{harmonic_mean}, jaccard = #{jaccard} where test_id = #{test_id}"
    res = DBConn.exec(query)
end

