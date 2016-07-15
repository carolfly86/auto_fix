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


	fqueryObj = QueryObj.new(fqueryScript,'f_table')
	pp fqueryObj
	tqueryObj = QueryObj.new('true','t_table')
	pp tqueryObj

	#
	puts "begin test"
	localizeErr = LozalizeError.new(fqueryObj,tqueryObj)
	selectionErrList = localizeErr.selecionErr()
	fqueryJson['score'] = localizeErr.getSuspiciouScore()
	puts "begin fix"
	hc=HillClimbingAlg.new(fqueryObj,tqueryObj)
	hc.hill_climbing(127)
end
def randomMutation(script)

	fqueryObj = QueryObj.new(script,'f_table')
	pp fqueryObj
	fqueryObj.generate_neighbor_program(128)
end