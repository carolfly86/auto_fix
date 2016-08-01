def queryTest(fqueryScript)
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

	f_options = {:script=> fqueryScript, :table =>'f_result' }
	fqueryObj = QueryObj.new(f_options)
	# pp fqueryObj
	t_options = {:script=> 'true', :table =>'t_result' }
	tqueryObj = QueryObj.new(t_options)
	#
	puts "begin test"
	beginTime = Time.now
	localizeErr = LozalizeError.new(fqueryObj,tqueryObj)
	selectionErrList = localizeErr.selecionErr()
	puts 'test end'
	endTime=Time.now
	fqueryObj.score = localizeErr.getSuspiciouScore()
	puts 'fquery score:'
	pp fqueryObj.score
	duration = (endTime - beginTime).to_i
	puts duration

	create_test_result_tbl()

	fquery = fqueryObj.query.gsub("'","''")
	tquery = tqueryObj.query.gsub("'","''")
	query =  %Q(INSERT INTO test_result 
				select 0,
				'"#{fquery}"',
				'"#{tquery}"',
				#{duration},
				'#{fqueryObj.score.to_s}'
			)	
	puts query
    DBConn.exec(query)

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
  	 pp query
    DBConn.exec(query)
end

