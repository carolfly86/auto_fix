require 'json'
require 'pg'
require 'pg_query'

# require_relative 'db_connection'

class QueryObj
  attr_reader :query, :pkList, :table, :parseTree
  attr_accessor :score
  OPR_SYMBOLS = [ ['='],['<>'], ['>'], ['<'], ['>='], ['<=']]

  def initialize(script,table)
    puts Dir.pwd
    @queryJson= JSON.parse(File.read("sql/#{script}.json"))
    @table=table
    @query=@queryJson['query']
    @pkList=@queryJson['pkList']
    @parseTree = PgQuery.parse(@query).parsetree[0]
    @score = 0
    DBConn.tblCreation(@table, @pkList, @query)

  end


end