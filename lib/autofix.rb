require 'jsonpath'
require 'pp'
module AutoFix
	# Find all the relations(tbls) from FROM Clause including their columns
  def AutoFix.JoinTypeFix(joinErrList,parseTree)
      
      fromPT = parseTree['SELECT']['fromClause'][0]
    	joinErrList.each do |err|
      		loc = err['location']
          joinSide = err['joinSide']
          joinType = err['joinType']
          case 
          # left Join, R side null is unwanted  
          when ( joinType.to_s =='1' and joinSide == 'R'  )
            # the fix would be change join from Left JOin to Inner Join
            fromPT = JsonPath.for(fromPT).gsub('$..JOINEXPR'){|v| update_joinType_by_loc(v,loc,'0')  }.to_hash
            # pp fromPT
          end


    	end 
      fromPTArry = []
      fromPTArry << fromPT
      JsonPath.for(parseTree).gsub('$..fromClause'){|v| fromPTArry}.to_hash

 	end

  def AutoFix.update_joinType_by_loc(json,loc, new_val)
    JsonPath.on(json, '$.rarg.RANGEVAR.location')[0] == loc ? JsonPath.for(json).gsub('$.jointype'){|v| new_val }.to_hash : json  
  end
end
