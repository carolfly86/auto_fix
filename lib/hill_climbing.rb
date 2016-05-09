require 'jsonpath'
require 'distribution'
# require_relative 'reverse_parsetree'
# require_relative 'db_connection'
# require_relative 'random_gaussian'
# require_relative 'localizeError'
class HillClimbingAlg
	def initialize(fQueryJson, tQueryJson)
		@max_iter = 100
		# probablity of adding noise
		@p = 0.8
	    @bouts = 5
	    @numericOperators = [['+'], ['-'], ['*'], ['/']]
	    # @keywords = [ 'AND', 'NOT', 'OR', '']
	    @oprSymbols= { 
	    	"~~" => [ ['='],['<>'], ['>'], ['<'],],
	    	"=" => [ ['<>'], ['>'], ['<'],],
	    	"<>" => [ ['='], ['>'], ['<'],],
	    	">"=> [ ['<'], ['<>'], ['='],],
	    	"<"=> [ ['>'], ['<>'], ['='],]
	    }
	    @fQueryJson=fQueryJson
	    @tQueryJson=tQueryJson
	    @pk= @fQueryJson['pkList']

	end
	def random_binary_str(length)
		str = ''
		while (length>0)
			str = str+rand(2).to_s
			length = length -1
		end
		return str
	end

	# Given a false query, location of suspicious predicate, along with additional information needed to validate the result
	# mutate the suspicious predicate, try to find a query that produces better score
	def hill_climbing(location)
		best = @fQueryJson
		score = @fQueryJson['score']
		loc =  location.to_s
		parseTree= @fQueryJson['parseTree']
		rst = parseTree.constr_jsonpath_to_location(location)

		last=rst.count-1
		rst.delete_at(last)

		predicatePath = '$..'+rst.map{|x| "'#{x}'"}.join('.')
		predicate = JsonPath.new(predicatePath).on(parseTree)
		
		generate_candiateList(predicate)
		generate_candidateConstList()
		pp @candidateConstList
		return 
		@tabuList=[]

		i = 0
		while ( i<=@max_iter and score[loc].to_i >0 )
			neighbor = generate_neighbor_program(parseTree,predicate,predicatePath)
			if neighbor.nil?
				puts 'no candidates available! '
				break
			end
			neighbor['table']='evl_tbl'
			evaluate_query(location,neighbor,@tQueryJson)
			s=neighbor['score']
			
			if s[loc].to_i < score[loc].to_i
				score = s
				best = neighbor
			end
			puts "iteration: #{i}"
			puts'current best query'
			puts best['query']
			i+=1
		end
	end


	private
	def generate_neighbor_program(parseTree,predicate,predicatePath)
		# mutateType = rand(3)
		mutateType = rand(7)+1
		element = Hash.new()
		puts "mutateType: #{mutateType}"
		newPredicate= predicate
		while (@tabuList.include?(element) or element.empty? )
			# if includes 1 then mutate column
			if ( mutateType & 1 ).to_s(2) != "0"
				type ='col'
			   	path = '$..COLUMNREF.fields'
			   	candidateList=@candidateColList
			   	oldVal = @column
			   	element['col']=rand_candicate(type,oldVal,candidateList)
			end
			# if includes 2 then mutate operator
			if ( mutateType & 2 ).to_s(2) != "0"
				type ='opr'
		   		path = '$..AEXPR.name'
		   		candidateList=@candidateOprList
		   		oldVal = @opr
				element['opr']=rand_candicate(type,oldVal,candidateList)
			end
			# if includes 4 then mutate constant
			if ( mutateType & 4 ).to_s(2) != "0"
				type ='const'
		   		path ='$..A_CONST.val'
		   		oldVal =@const
		   		col = element['col'] || @column
		   		opr = element['opr'] || @opr
		   		element['const']=rand_constant(col, opr, oldVal)
			end
		end
		puts "element"
		pp element
		element.keys.each do |key|
			pp key
			newPredicate = mutatePredicate(key,element[key],predicate)
		end
		newPS=JsonPath.for(parseTree).gsub(predicatePath){|v| newPredicate}
		newQuery = ReverseParseTree.reverse(newPS.obj)
		newQueryJson = @fQueryJson.clone

		newQueryJson['query'] = newQuery
		newQueryJson['parseTree'] = newPS.obj
		newQueryJson['score']=Hash.new()
		pp "new query"
		pp newQuery
		return newQueryJson
	end
	def mutatePredicate(type,newVal,predicate)
 		path = case type
		 		when 'const'
		 			'$..A_CONST.val'
		 		when 'col'
		 		    '$..COLUMNREF.fields'
		 		when 'opr'
		 			'$..AEXPR.name'
		 		end
		pp path 		
		JsonPath.for(predicate).gsub!(path){|v| newVal}
		return predicate[0]	
	end
	def evaluate_query(location,evlQueryJson,tQueryJson)
		DBConn.tblCreation(evlQueryJson['table'],evlQueryJson['pkList'], evlQueryJson['query'])
		localizeErr = LozalizeError.new(evlQueryJson,tQueryJson,false)
	    localizeErr.selecionErr()
	    score = localizeErr.getSuspiciouScore()
	    evlQueryJson['score']=score
	end
	def rand_candicate(type,oldVal,candidateList)
		# element = Hash.new()
		case type
		# when 'const'
		# 	randVal = rand()
		# 	newVal = oldVal + randVal
		# 	# element['const']=newVal
		when 'col'
			newVal = oldVal
			while (newVal == oldVal)
				newCol = candidateList[rand(candidateList.size)]
				newVal = Array.new()
				newVal << newCol.relalias
				newVal << newCol.colname
			end
		when 'opr'
			newVal = oldVal
			while (newVal == oldVal)
				newVal = candidateList[rand(candidateList.size)]
			end
		end
		puts "newval: #{newVal}"
		newVal
	end
	def rand_constant(col, opr, oldVal)
		case opr
		when '>', '>='
			newVal = '100'
		when '<', '<='
			newVal = '10000'
		# when '='
		else
			newVal = '1000'
		end
	end
	def generate_candiateList(predicate)
		fromPT = @fQueryJson['parseTree']['SELECT']['fromClause']
		@column = JsonPath.on(predicate, '$..COLUMNREF.fields').to_a()[0]
		@opr = JsonPath.on(predicate, '$..AEXPR.name').to_a()[0]
		@const = JsonPath.on(predicate, '$..A_CONST.val').to_a()[0]
		@candidateColList = DBConn.findRelFieldListByCol(fromPT, @column)
		# remove @column from candidateColList
		oldColIdx =@candidateColList.find_index do |item|
						if @column.count>1
							@column.join('.') == "#{item.relalias}.#{item.colname}"
						else
							@column[0] == item.colname
						end
					end
		@candidateColList.delete_at(oldColIdx)
		@candidateOprList = @oprSymbols[@opr[0]]

	end
	def generate_candidateConstList()
		@candidateConstList =Hash.new()
		columns = @candidateColList.clone
		column = Column.new
        column.colname = @column.count>1 ? @column.join('.') : @column[0]
		columns << column
		columns.each do |col|
			min = get_min_max_val(col.colname,'min')
			max = get_min_max_val(col.colname,'max')
			colVal = Hash.new()
			colVal={min: min, max: max}
			@candidateConstList[col.colname] = colVal
			pp @candidateConstList
		end
	end
	def get_min_max_val(col,type)
		# find correct pks (Union of missing pk and satisfied pk)
		# for now we get them from t_result
		pkquery = "select #{@pk} from t_result"
		parseTree= @fQueryJson['parseTree']
		fromPT = @fQueryJson['parseTree']['SELECT']['fromClause']
		fields = DBConn.getAllRelFieldList(fromPT)
		# remove the where clause in query
		whereClauseReplacement = Array.new()
		query_with_no_whereClause =  ReverseParseTree.reverseAndreplace(parseTree, '*',whereClauseReplacement)
		pp query_with_no_whereClause

		pkjoin = @pk.split(',').map{|pkcol|  "pk.#{pkcol} = t.#{pkcol}" }.join(' AND ')
		# fromPT = @fQueryJson['parseTree']['SELECT']['fromClause']		
		query = "with pk as (#{pkquery}), t as (#{query_with_no_whereClause}) 
				select #{type}(t.#{col})  from t join pk on #{pkjoin}"

		pp query
		rst = DBConn.exec(query)
		pp rst[0]

	end

end
