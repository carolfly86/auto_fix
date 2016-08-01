module RewriteQuery
  # rewrite the query to return all fields in all reltaions.
  # also rename columns appearing in more than one relation.
  # for example, updated_date column is in both customer table and address table, 
  # then the updated_date in customer table will be selected as customer_updated_date, 
  # and the one in address table will be address_updated_date
  def RewriteQuery.return_all_fields(query)
    parseTree = PgQuery.parse(query).parsetree[0]
  #distinct = parseTree['SELECT']['distinctClause']||''
    fromPT = parseTree['SELECT']['fromClause']
    fields = DBConn.getAllRelFieldList(fromPT)
    newTargetList = []
    rewriteCols =Hash.new()
    fields.group_by{|f| f.colname}.each do |key, val|
      col = if val.size >1
              rewriteCols[key] = val
              val.map{|c| "#{c.relalias}.#{c.colname} as #{c.relname}_#{c.colname}" }.join(',') 
            else
                val.map{|c| "#{c.relalias}.#{c.colname}" }.join(',') 
            end
      newTargetList << col
    end 
    targetListReplacement = newTargetList.join(',')
    newQuery =  ReverseParseTree.reverseAndreplace(parseTree, targetListReplacement,'')
    return newQuery, rewriteCols
  end

  def RewriteQuery.rename_duplicate_columns(colList)
    colList.group_by{|f| f.colname}.each do |key, val|
      if val.size >1
        val.each do |col|
          pp 
          col.colalias = col.relname.to_s.empty? ? "#{col.relalias}_#{col.colname}" : "#{col.relname}_#{col.colname}"
        end
      else
        col = val[0]
        col.colalias = col.colname
      end
    end
  end
  class << self
    # create below methods to replace col attribute in query
    #  :replace_colname_with_colalias,
    #  :replace_colname_with_fullname,
    #  :replace_colname_with_expr,
    #  :replace_colalias_with_colname,
    #  :replace_colalias_with_fullname,
    #  :replace_colalias_with_expr,
    #  :replace_fullname_with_colname,
    #  :replace_fullname_with_colalias,
    #  :replace_fullname_with_expr,
    #  :replace_expr_with_colname,
    #  :replace_expr_with_colalias,
    #  :replace_expr_with_fullname
    c = ['colname','colalias','fullname','expr']
    c.product(c).delete_if{|c| c[0]==c[1]}.each do |type|
      define_method("replace_#{type[0]}_with_#{type[1]}") do |query, col|
          eval("col.#{type[0]}.nil? ? query : col.#{type[1]}.nil? ? query : query.gsub(col.#{type[0]},col.#{type[1]})")
      end
    end
  end 
  # def RewriteQuery.replace_fullname_with_expr(query,col)
  #   query.gsub(col.fullname,col.expr)
  # end
  # def RewriteQuery.replace_fullname_with_colalias(query,col)
  #   query = query.gsub(col.fullname,col.colalias) unless col.colalias.to_s.empty?
  #   query
  # end
  # def RewriteQuery.remove_tbl_alias(query,col)
  #   query.gsub(col.fullname,col.colname)
  # end
end