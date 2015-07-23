require 'jsonpath'
require_relative 'reverse_parsetree'
require_relative 'db_connection'
require_relative 'random_gaussian'
require_relative 'localizeError'
class HillClimbingAlg
	def initialize(parseTree,tTable)
		@max_gens = 100
	    @max_depth = 4
	    @expr_max_depth = 2
	    @pop_size = 100
	    @bouts = 5
	    @p_repro = 0.08
	    @p_cross = 0.90
	    @p_mut = 0.02
	    @numericOperators = [['+'], ['-'], ['*'], ['/']]
	    @keywords = [ 'AND', 'NOT', 'OR', '']
	    @eqSymbols= [['='], ['>'], ['<'],['<>']]
	    @ps = parseTree
	    @tTable = tTable

	    pkListQuery = QueryBuilder.find_pk_cols(@tTable)
    	res = DBConn.exec(pkListQuery)
    	@pkList = []
    	res.each do |r|
      		@pkList << r['attname']
    	end

	    @fromPT =  @ps['SELECT']['fromClause']
	    @fieldsList = DBConn.getRelFieldList(@fromPT)
	    @numericDataTypes = ['smallint','integer','bigint','decimal','numeric','real','double precision','serial','bigserial']
	   	@constList = -10.step(10).to_a
	    @wherePT = @ps['SELECT']['whereClause']
	    # @parentAEXPR =0

	end
	def generate_neighbor_program(wherePT)
		# neighborPS = parseTree
		mutateType = rand(3)
		if mutateType == 0
			neighborPS = mutateConstant(wherePT)
		elsif mutateType == 1
			neighborPS = mutateColumn(wherePT)
		elsif mutateType == 2
			neighborPS = mutateOperator(wherePT)
		end
		pp neighborPS			

	end
	
	def evaluate_query(parseTree,pkList,fTable)
		evl_query = ReverseParseTree.reverse(parseTree)	
		query = QueryBuilder.create_tbl(fTable, pkList, query)
		DBConn.exec(query)
		localizeErr = LozalizeError.new(evl_query, fTable, @tTable)

		query,unWantedCount = localizeErr.find_unwanted_tuples(true)
		query,missingCount = localizeErr.find_missing_tuples(true)

		
		query = 'SELECT COUNT(1) FROM #{fTable};'
		totalCount = DBConn.exec(query)[0][0]
		# what is totalCount is 0 ?
		(unWantedCount[0][0]+missingCount[0][0])/totalCount

	end
	private
	def mutateConstant(parseTree)
		rand_element_replace(parseTree, '$..A_CONST.val', @constList)
	end

	def mutateColumn(parseTree)
		rand_element_replace(parseTree, '$..COLUMNREF.fields', @fieldsList)
	end
	def mutateOperator(parseTree)
		rand_element_replace(parseTree, '$..AEXPR.name', @eqSymbols)
	end	

	def rand_element_replace(json, path, choiceList)
		i = -1
		#oldVal =  nil 
		randVal = nil
		nodePos = nil
		jsonList = JsonPath.on(json, path).to_a
 		candidateList = []
		jsonList.each_with_index do |n,i|
			candidateList<<[n,i] if choiceList.include? n
		end
		return json if candidateList.count() == 0

		node = choiceList[rand(choiceList.size)]
		randVal = oldVal = node[0]		
		nodePos = node[1]
		p randVal
		p oldVal

		while randVal == oldVal
			randVal = candidateList[rand(candidateList.size)]
		end

		JsonPath.for(json).gsub!(path) do |n|
			i = i + 1
			# newVal = randVal
			i == nodePos ? randVal : n
		end
		#return modified json
		json	
	end

end
