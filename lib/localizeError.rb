require 'pg'
require 'pg_query'
require 'jsonpath'
require 'rubytree'
require_relative 'reverse_parsetree'
require_relative 'string_util'
require_relative 'hash_util'
require_relative 'array_helper'

require_relative 'query_builder'
require_relative 'db_connection'

class LozalizeError
  # attr_accessor :fPS
  #def initialize(fQuery, tQuery, parseTree)
  def initialize(fQueryObj,tQueryObj, is_new = true)
    # @fQuery=fqueryObj['query']
    # @tQuery=tqueryObj['query']

    @fQueryObj = fQueryObj
    @tQueryObj = tQueryObj

    @fTable = fQueryObj.table
    @tTable =  tQueryObj.table  

    @fPS = fQueryObj.parseTree
    @tPS=tQueryObj.parseTree

    @is_new = is_new
    @test_id = @is_new ? 0 : generate_new_testid()

    @pkListQuery = QueryBuilder.find_pk_cols(@tTable)
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

    @wherePT = @fPS['SELECT']['whereClause']
    @fromPT =  @fPS['SELECT']['fromClause']
    # generate predicate tree from where clause
    root =Tree::TreeNode.new('root', '')
    @predicateTree = PredicateTree.new('f',@is_new, @test_id)
    # pp @wherePT
    @predicateTree.build_full_pdtree(@wherePT,root)
    @pdtree = @predicateTree.pdtree
    @pdtree.print_tree
    pp 'branches'
    pp @predicateTree.branches
    pp 'nodes'
    pp @predicateTree.nodes

    # @predicateTree.node_query_mapping_insert()

    #pp whereCondArry.to_a
    @fromCondStr = ReverseParseTree.fromClauseConstr(@fromPT)
    @whereStr = ReverseParseTree.whereClauseConst(@wherePT)

    # create_t_f_union_table
    # create_t_f_intersect_table
    # create_t_f_all_table

  end
  def generate_new_testid()
    query = "select max(test_id) as test_id from node_query_mapping"
    rst = DBConn.exec(query)
    if rst.count() == 0
      0
    else
      rst[0]['test_id'].to_i + 1
    end
  end

  def create_t_f_union_table()
    query = "select #{@pkSelect} from #{@tTable} UNION select #{@pkSelect} from #{@fTable}"
    query =QueryBuilder.create_tbl('t_f_union',@pkList,query)
    puts'create t_f_union'
    puts query
    # create
    DBConn.exec(query)
  end
  def create_t_f_intersect_table()
    query = "select #{@pkSelect} from #{@tTable} INTERSECT select #{@pkSelect} from #{@fTable}"
    query =QueryBuilder.create_tbl('t_f_union',@pkList,query)
    puts'create t_f_intersect'
    puts query
    # create
    DBConn.exec(query)
  end 
  def create_t_f_all_table()
      query =  ReverseParseTree.reverseAndreplace(@fParseTree, @pkList,'')
      query = QueryBuilder.create_tbl('t_f_all',@pkList,query)
      puts'create t_f_all'
      puts query
      DBConn.exec(query)
  end 
  def similarityBitMap()
    colList = @pkSelect.gsub(/f\./,'').split(',').map{|c| "t.#{c} as #{c}_pk, CASE WHEN t.#{c} is null or f.#{c} is null then 0 else 1 END as #{c}"}.join(',')
    colCnt = ''
    sumCnt = ''
    matchingColQuery = QueryBuilder.find_matching_cols(@tTable, @fTable)
   # p matchingColQuery
    matchingCol = DBConn.exec(matchingColQuery)
    matchingCol.each do |r|
      unless @pkList.include? r['col1']
        if (r['is_matching'] == '1')
          colList += " , CASE WHEN t.#{r['col1']} = f.#{r['col1']} then 1 else 0 end as #{r['col1']}" 
          colCnt += " sum(#{r['col1']}) as #{r['col1']}_cnt,"
          sumCnt += "#{r['col1']}_cnt+"
        else  
          colList += r['col1'].nil? ? " , 0 as #{r['col2']}" : " , 0 as #{r['col1']}"
        end
      end
    end
    query = "drop table if exists similarityBitMap; select #{colList} into similarityBitMap from #{@fTable} f FULL OUTER JOIN #{@tTable} t ON #{@pkJoin}"    
    # p query
    DBConn.exec(query)
    query = "select count(1) as total_cnt from similarityBitMap"
    res = DBConn.exec(query)
    total_cnt = res[0]['total_cnt'].to_f
    # puts "total_cnt: #{total_cnt}"
    colNum = (matchingCol.count - @pkList.count).to_f
    # puts "colNum: #{colNum}"

    total_field = total_cnt*colNum
    # puts "total_field: #{total_field}"
    colCnt = colCnt[0...-1]
    sumCnt = sumCnt[0...-1]
    query = "with t as(select #{colCnt} from similarityBitMap) select #{sumCnt} as sum from t;"
    # puts query
    res = DBConn.exec(query)
    sum = res[0]['sum'].to_f

    # puts "sum: #{sum}"

    puts "similarity: "
    puts (sum/total_field).to_f
    (sum/total_field).to_f
  end
  # projection error localization
  def projErr()

    projErrList =[]
    targetList = @fPS['SELECT']['targetList']


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
    return if @fPS['SELECT']['fromClause'][0]['JOINEXPR'].nil?

    if testDataType == "U" # unwanted
      fromCondStr = @fromCondStr
    else
      #for missing data set, we need to replace all join to OUTER JOIN
      fromPT = JsonPath.for(@fromPT.to_json).gsub('$..jointype') {|v| "2" }.to_hash
      fromCondStr = ReverseParseTree.fromClauseConstr(fromPT)
      #p fromCondStr
    end
    joinErrList = []
    joinJson = @fPS['SELECT']['fromClause'][0].to_json
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
      pkNodes <<  ReverseParseTree.find_col_by_name(@fPS['SELECT']['targetList'], c)
    end
    pkNodes.compact!
    #pp pkNodes.to_a
    reversedPKList = pkNodes.map{ |n| n['col'] }.join(',')


    query = "SELECT #{reversedPKList} FROM #{fromCondStr} " 
    query += @whereStr.length>0 ? "WHERE #{@whereStr} AND #{pkNull}" : " WHERE #{pkNull}"

    testQuery = QueryBuilder.subset_test(query, pkQuery)
      
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
    query,res = find_unwanted_tuples()
    #res = DBConn.exec(query)
    unWantedPK = pkArryGen(res)

    tnTableCreation('tuple_node_test_result') if @is_new

    if unWantedPK.count()>0
      p 'Unwanted Pk'
      # create unwanted_tuple_branch table
      whereErrList = whereCondTest(unWantedPK,'U')
      joinErrList = jointypeErr(query,'U')
    end 


    # Missing rows
    query,res = find_missing_tuples()

    missinPK = pkArryGen(res)
    # Join type test
    # Join condition test
    # where clause test
    # if missinPK.count()>0
    #   p 'Missing PK'

    #   whereErrList = whereCondTest(missinPK,'M')
    #   joinErrList = jointypeErr(query,'M')
    # end

    #p joinErrList.to_a 
    #p whereErrList.to_a
    # predicateArry = @predicateTree.predicateArrayGen(@pdtree)
    # pp predicateArry
    suspicious_score_upd(@predicateTree.branches)
    true_query_PT_construct()
    tuple_mutation_test(missinPK,'M')
    tuple_mutation_test(unWantedPK,'U')

    # remove constraint_nodes in node_query_mapping
    query = "delete from node_query_mapping where test_id = #{@test_id} and type = 't'"
    DBConn.exec(query)

    j = Hash.new
    j['JoinErr'] = joinErrList
    j['WhereErr'] = whereErrList
    j
  end
  def true_query_PT_construct()
    tWherePT= @tPS['SELECT']['whereClause']
    tPredicateTree = PredicateTree.new('t',false, @test_id)
    root =Tree::TreeNode.new('root', '')
    tPredicateTree.build_full_pdtree(tWherePT,root)
    # tPredicateTree.node_query_mapping_insert()

  end
  def tuple_mutation_test(pkArry, type)

    # tPredicateArry =tPredicateTree.predicateArrayGen(tPDTree)

    pkArry.each do |pk|
      # pp pk
      # pp type
      pkCond=QueryBuilder.pkCondConstr(pk)
      if type =='U'
        # only need exonerating if multiple nodes in a branch are suspicious
        branchQuery="select distinct branch_name from tuple_node_test_result where #{pkCond};" 
        pp branchQuery
        res = DBConn.exec(branchQuery)
        res.each do |branch_name|
          # distinct_query = "select distinct node_name from node_query_mapping where branch_name = '#{branch_name['branch_name']}'"
          # distinct_nodes =DBConn.exec(distinct_query)
          # if distinct_nodes.count()>1
            branch =[]
            branch << @predicateTree.branches.find{ |br| br.name == branch_name['branch_name'] }
            pp branch
            tupleMutation = TupleMutation.new(@test_id,pk,type,branch,@fQueryObj,@tQueryObj)
            tupleMutation.unwanted_to_satisfied()
          # end
        end
      elsif type == 'M'
         # only need exonerating if multiple branches are suspicious
          branchQuery="select distinct branch_name from tuple_node_test_result where #{pkCond};"
          res = DBConn.exec(branchQuery)
          if res.count()>1
            tupleMutation = TupleMutation.new(@test_id,pk,type,@predicateTree.branches,@fQueryObj,@tQueryObj) 
            tupleMutation.missing_to_excluded
          end
      end
    end

  end

  def suspicious_score_upd(predicate_tree_branches)
    predicate_tree_branches.each do |br|
      br.nodes.each do |nd|
        query = "suspicious_score = #{nd.suspicious_score}"
        @predicateTree.node_query_mapping_upd(br.name,nd.name,query)
      end
    end
  end
  # create tuple node table
  def tnTableCreation(tableName)
      q = QueryBuilder.create_tbl(tableName, '', "select #{@pkSelect} from #{@fTable} f where 1 = 0")
      DBConn.exec(q)

      q="ALTER TABLE #{tableName} add column test_id int, add column node_name varchar(30), add column branch_name varchar(30), add column type varchar(5);"
      DBConn.exec(q)
  end
  def pkArryGen(res)
    pkArry = []
    res.each do |r|
      pk = []
      @pkList.each do |c|
        h =  Hash.new
        #col = ReverseParseTree.find_col_by_name(@ps['SELECT']['targetList'], c)['fullname']
        h['col'] = ReverseParseTree.find_col_by_name(@fPS['SELECT']['targetList'], c)['col']
        h['val'] = r[c]
        pk.push(h)
      end
      pkArry.push(pk)
    end
    pkArry
  end

  def getSuspiciouScore()
    query = "select * from node_query_mapping where test_id = #{@test_id}"
    rst = DBConn.exec(query)
    score = Hash.new()
    score["totalScore"] = 0
    rst.each do |t|
      score["totalScore"] += t['suspicious_score'].to_i
      loc = t['location']
      score[loc] = t['suspicious_score']
    end
    score
  end

  def whereCondTest(pkArry, type)

    return if @wherePT.nil?
    # whereCondArry = ReverseParseTree.whereCondSplit(@wherePT)
    selectQuery = 'SELECT COUNT(1) FROM '+@fromCondStr +' WHERE '
    # p selectQuery
    pkArry.each do |pk|

      @predicateTree.branches.each do |branch|
        branchQuery = selectQuery + QueryBuilder.pkCondConstr(pk)
        nodeQuery = branchQuery
        pkVal = QueryBuilder.pkValConstr(pk)
        # pp'branch'
        # branch.print_tree
        # pp'--------'
        currentNode = branch
        branch.nodes.each do |node|
          # currentNode = currentNode.children[0]
          # currentNode.print_tree
          # # p currentNode.has_children?
          # pp currentNode.name
          # pp currentNode.content
          # unless currentNode.name=~ /^PH*/
          # content = node.content
          branchQuery = branchQuery+' AND ' + node.query
          nodeQuery_new = nodeQuery +' AND ' + node.query
          # suspicious score+ for each node fails missing tuple
          if type =='M'
            # puts 'nodeQuery_new'
            # pp nodeQuery_new
            res = DBConn.exec(nodeQuery_new)
            #pp res[0]['count']
            if res[0]['count'].to_i==0
              # p 'failed!'
              # pp nodeQuery_new
              node.suspicious_score +=1
              # pp currentNode.content
              query = "INSERT INTO tuple_node_test_result values (#{pkVal}, #{@test_id},'#{node.name}', '#{branch.name}','M')"
              DBConn.exec(query)
            else
              # p 'passed'
              # pp nodeQuery
              nodeQuery = nodeQuery_new
            end
          end
          # end

        end

        # suspicious score+ for each BRANCH that passes unwanted tuple
        if type =='U'
          # puts'U'
          # puts branchQuery
          res = DBConn.exec(branchQuery)
          #pp res[0]['count']
          if res[0]['count'].to_i>0
            # p 'failed'
            # pp branchQuery
            # pp currentNode.has_children?
            currentNode = branch
            # puts 'currentNode'
            # pp currentNode
            branch.nodes.each do |node|
              # currentNode = currentNode.children[0]
              # unless currentNode.name=~ /^PH*/ 
              query = "INSERT INTO tuple_node_test_result values (#{pkVal},#{@test_id},'#{node.name}', '#{branch.name}','U')"
              DBConn.exec(query)
              node.suspicious_score +=1
              # end
            end
          end
        end 
      end
    end
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
    puts query
    return query, res
  end


end