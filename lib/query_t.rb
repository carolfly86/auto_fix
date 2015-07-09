require 'json'
require 'pg'
require_relative 'db_connection'

class QueryT

  def initialize(queryJson, table)
    @queryJson=queryJson
    @table=table
   # @cfg = cfg
    @query=''
    @pkList=''

    createTable()
  end
  def createTable()
    #conn = PG::Connection.open(dbname: @cfg['default']['database'], user: @cfg['default']['user'], password: @cfg['default']['password'])

    #queryJson = JSON.parse(File.read("sql/#{@file}"))
    @query = @queryJson['query']
    @pkList= @queryJson['pkList']
    puts @query
    puts @pkList

    insert = @query.insert(@query.index('from'), " INTO #{@table} ")
    tblCreate =  "DROP TABLE IF EXISTS #{@table}; #{insert}"
    puts tblCreate
    DBConn.exec(tblCreate)

    pkCreate = "ALTER TABLE #{@table} ADD PRIMARY KEY (#{@pkList});"
    puts pkCreate
    DBConn.exec(pkCreate)
  end
  attr_reader :query
  attr_reader :pkList
  attr_reader :table

end