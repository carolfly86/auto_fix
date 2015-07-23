require 'pg'
require 'pg_query'
require 'jsonpath'
require_relative 'reverse_parsetree'
require_relative 'string_util'
require_relative 'hash_util'
require_relative 'query_builder'
require_relative 'db_connection'
require_relative 'query_builder'
class LozalizeError

  #def initialize(fQuery, tQuery, parseTree)
  def initialize(fQuery, fTable, tTable)
    @fQuery=fQuery
    @fTable = fTable
    #@tQuery=tQuery
    @tTable = tTable    
    @ps = PgQuery.parse(fQuery).parsetree[0]

    @pkListQuery = QueryBuilder.find_pk_cols(tTable)
    res = DBConn.exec(@pkListQuery)
    @pkList = []
    res.each do |r|
      @pkList << r['attname']
    end

    #pp @ps
    @pkJoin = ''
    pkSelectArry =[]
    pkJoinArry = []
    @pkList.each do |c|
      pkJoinArry.push("t.#{c} = f.#{c}")
      pkSelectArry.push("f.#{c}" )
    end
    #pp @pkList
    @pkSelect = pkSelectArry.join(',')
    @pkJoin = pkJoinArry.join(' AND ')

    @wherePT = @ps['SELECT']['whereClause']
    @fromPT =  @ps['SELECT']['fromClause']
    #pp whereCondArry.to_a
    @fromCondStr = ReverseParseTree.fromClauseConstr(@fromPT)
    @whereStr = ReverseParseTree.whereClauseConst(@wherePT)



  end
  # projection error localization
  def projErr()

    projErrList =[]
    targetList = @ps['SELECT']['targetList']


    targetList.each_with_index do |node,index|
      #pp n
      col = ReverseParseTree.colNameConstr(node)
      # node['RESTARGET']['name'] || ( node['RESTARGET']['val']['COLUMNREF']['fields'].count()==1 ) ? node['RESTARGET']['val']['COLUMNREF']['fields'][0] : node['RESTARGET']['val']['COLUMNREF']['fields'][1]
      colName = col['alias']
      #puts colName
      #p colName
      unless @pkList.include? colName
        query = "select count(1) from #{@fTable} f JOIN #{@tTable} t ON #{@pkJoin} WHERE t.#{colName} != f.#{colName}"
        #p query
        res = DBConn.exec(query)
        if (res.getvalue(0,0).to_i>0)
          #puts "index:#{index}"
          projErrList.push(index)
        end
      end
    end
    projErrList
  end

  # join type error localization
  def jointypeErr(pkQuery,testDataType)
    return if @ps['SELECT']['fromClause'][0]['JOINEXPR'].nil?

    if testDataType == "U" # unwanted
      fromCondStr = @fromCondStr
    else
      #for missing data set, we need to replace all join to OUTER JOIN
      fromPT = JsonPath.for(@fromPT.to_json).gsub('$..jointype') {|v| "2" }.to_hash
      fromCondStr = ReverseParseTree.fromClauseConstr(fromPT)
      #p fromCondStr
    end
    joinErrList = []
    joinJson = @ps['SELECT']['fromClause'][0].to_json
    joinList = JsonPath.on(joinJson, '$..JOINEXPR')
    joinList.each do |join|
      joinType = join['jointype']
      larg = join['larg']
      lLoc = JsonPath.on(larg, '$..location')[0]

      rarg = join['rarg']
      rLoc = JsonPath.on(rarg, '$..location')[0]
      

      # pp join
      # join null testing is not needed for inner join, unwanted dataset
      unless joinType.to_s == "0" and testDataType == "U"
        #LEFT NULL
        lNull = joinArgNull(larg)
        lRst = joinNullTest(lNull,pkQuery, fromCondStr)
        joinErrList << joinNullRst(lRst,joinType,'L', lLoc)
         #Right Null      
        rNull = joinArgNull(rarg)
        rRst = joinNullTest(rNull,pkQuery, fromCondStr)
        joinErrList << joinNullRst(rRst,joinType, 'R', rLoc)
      end

    end
    joinErrList.compact!

  end


  def joinArgNull(arg)
    h = Hash.new()
    h = arg
    relList = h.find_all_values_for('RANGEVAR')
    pkNull = []
    relList.each do |r|
      rel = ReverseParseTree.relnameConstr(r)
      relName = rel['relname']
      relAlias = rel['alias']
      relFullName = rel['fullname']
      query = QueryBuilder.find_pk_cols(relName)
      pkCol = DBConn.exec(query)
      # pkList << pkCol.map{ |row| relAlias + ' '+ row['attname']}.join(', ')
      pkNull << pkCol.map{ |row| relAlias + '.'+ row['attname'] + ' is null'}.join(' AND ')
    end
    pkNull.join(' AND ')  
  end 

  def joinNullTest(pkNull,pkQuery, fromCondStr)
    pkNodes = []
    @pkList.each do |c|
      pkNodes <<  ReverseParseTree.find_col_by_name(@ps['SELECT']['targetList'], c)
    end
    pkNodes.compact!
    #pp pkNodes.to_a
    reversedPKList = pkNodes.map{ |n| n['col'] }.join(',')


    query = "SELECT #{reversedPKList} FROM #{fromCondStr} " 
    query += @whereStr.length>0 ? "WHERE #{@whereStr} AND #{pkNull}" : " WHERE #{pkNull}"
    #p query
    testQuery = QueryBuilder.subset_test(query, pkQuery)
    #p query      
    res = DBConn.exec(testQuery)  
    #p testQuery
    result = res[0]['result']

    unless result == "IS SUBSET"
      testQuery = QueryBuilder.subset_test(pkQuery, query)
    #p query      
      res = DBConn.exec(testQuery)  
      #p testQuery
      result = res[0]['result']
    end
    result
  end
  
  def joinNullRst(rst,jointype,joinSide, location)
    # p rst 
    if rst == "IS SUBSET"
      joinTypeDesc = ReverseParseTree.joinTypeConvert(jointype.to_s)
      #p "Error in Join type #{joinTypeDesc} of #{joinSide}"
      h = Hash.new()
      h['location'] = location
      h['joinSide'] = joinSide
      h['joinType'] = jointype
      h
    end
  end




  # where cond error localization
  def selecionErr
    whereErrList = []
    joinErrList = []
    # pkNull = @pkSelect.gsub(',',' IS NULL AND ')

    # # Unwanted rows
    #query = "SELECT #{@pkSelect} FROM #{@fQuery.table} f LEFT JOIN #{@tQuery.table} t ON #{@pkJoin} where #{pkNull.gsub('f.','t.')} IS NULL"
    #p query
    query,res = find_unwanted_tuples()
    #res = DBConn.exec(query)
    unWantedPK = pkArryGen(res)
    # Join type test
    # jointypeErr(query,'Unwanted')
    if unWantedPK.count()>0
      p 'Unwanted Pk'
      #p query
      whereErrList = whereCondTest(unWantedPK,'U')
      joinErrList = jointypeErr(query,'U')
    end 


    # Missing rows
    #query = "SELECT #{@pkSelect.gsub('f.','t.')} FROM #{@tQuery.table} t LEFT JOIN #{@fQuery.table} f ON #{@pkJoin} where #{pkNull} IS NULL"
    # #p query
    # res = DBConn.exec(query)
    query,res = find_missing_tuples()

    missinPK = pkArryGen(res)
    # Join type test
    # Join condition test
    # where clause test
    if missinPK.count()>0
      p 'Missing PK'
      #p query
      whereErrList = whereCondTest(missinPK,'M')
      joinErrList = jointypeErr(query,'M')
    end 
    #p joinErrList.to_a 
    #p whereErrList.to_a

    j = Hash.new
    j['JoinErr'] = joinErrList
    j['WhereErr'] = whereErrList
    j
  end

  def pkArryGen(res)
    pkArry = []
    res.each do |r|
      pk = []
      @pkList.each do |c|
        h =  Hash.new
        #col = ReverseParseTree.find_col_by_name(@ps['SELECT']['targetList'], c)['fullname']
        h['col'] = ReverseParseTree.find_col_by_name(@ps['SELECT']['targetList'], c)['col']
        h['val'] = r[c]
        pk.push(h)
      end
      pkArry.push(pk)
    end
    pkArry
  end


  def whereCondTest(pkArry, type)

    return if @wherePT.nil?
    whereCondArry = ReverseParseTree.whereCondSplit(@wherePT)
    selectQuery = 'SELECT COUNT(1) FROM '+@fromCondStr +' WHERE '
    # p selectQuery
    pkArry.each do |pk|
      query = selectQuery + pkCondConstr(pk)
      whereCondArry.each do |cond|
        currentQuery = query +' AND ' + cond['query']
        # p type
        # p currentQuery
        res = DBConn.exec(currentQuery)
        #pp res[0]['count']
        if res[0]['count'].to_i>0
          query = currentQuery
        else
           cond['suspicious_score'] +=1 
        end
        # p query
      end
    end
    whereCondArry

  end

  def pkCondConstr(pk)
    pk.map{|pk| pk['col']+' = '+ pk['val'].to_s.str_int_rep }.join(' AND ')
    #p pkcond
  end

  def find_unwanted_tuples(count_only = false)
    pkNull = @pkSelect.gsub(',',' IS NULL AND ')
    # Unwanted rows
    query = 'SELECT '+
            ( count_only ?  'count()' : @pkSelect )+
            " FROM #{@fTable} f LEFT JOIN #{@tTable} t ON #{@pkJoin} where #{pkNull.gsub('f.','t.')} IS NULL"
    res = DBConn.exec(query)
    return query,res
  end
  def find_missing_tuples(count_only = false)
    pkNull = @pkSelect.gsub(',',' IS NULL AND ')
    # Unwanted rows
    query = 'SELECT '+
             ( count_only ?  'count()': @pkSelect.gsub('f.','t.'))+
             " FROM #{@tTable} t LEFT JOIN #{@fTable} f ON #{@pkJoin} where #{pkNull} IS NULL"
    res = DBConn.exec(query)
    return query, res
  end


end