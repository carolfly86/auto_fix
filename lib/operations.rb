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
				f_options = {:query=> query, :pkList =>pk_list,  :table =>'f_result' }
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
	f_options_list.each do |f_options|
		puts "begin test"
		beginTime = Time.now
		fqueryObj = QueryObj.new(f_options)
		tqueryObj = QueryObj.new(t_options)
		localizeErr = LozalizeError.new(fqueryObj,tqueryObj)
		selectionErrList = localizeErr.selecionErr()
		puts 'test end'
		endTime = Time.now
		fqueryObj.score = localizeErr.getSuspiciouScore()
		puts 'fquery score:'
		pp fqueryObj.score
		duration = (endTime - beginTime).to_i
		puts "duration: #{duration}"
		update_test_result_tbl(fqueryObj.query,tqueryObj.query,duration,fqueryObj.score)
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
	(test_id int, fquery text, tquery text, duration bigint, result text);)
  	 # pp query
    DBConn.exec(query)
end
def update_test_result_tbl(fquery,tquery,duration,score)

	fquery = fquery.gsub("'","''")
	tquery = tquery.gsub("'","''")

	query =  %Q(INSERT INTO test_result
				select 0,
				'"#{fquery}"',
				'"#{tquery}"',
				#{duration},
				'#{score.to_s}'
			)
	# puts query
    DBConn.exec(query)
end

