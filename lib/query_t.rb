require 'json'
require 'pg'
class QueryT

  def initialize(file, table, cfg)
    @file=file
    @table=table
    @cfg = cfg
    @query=''
    @pkList=''

    createTable()
  end
  def createTable()
    conn = PG::Connection.open(dbname: @cfg['default']['database'], user: @cfg['default']['user'], password: @cfg['default']['password'])

    jFile = JSON.parse(File.read("sql/#{@file}"))
    @query = jFile['query']
    @pkList=jFile['pkList']
    puts @query
    puts @pkList

    insert = @query.insert(@query.index('from'), " INTO #{@table} ")
    tblCreate =  "DROP TABLE IF EXISTS #{@table}; #{insert}"
    puts tblCreate
    conn.exec(tblCreate)

    pkCreate = "ALTER TABLE #{@table} ADD PRIMARY KEY (#{@pkList});"
    puts pkCreate
    conn.exec(pkCreate)
  end
  attr_reader :query
  attr_reader :pkList
  attr_reader :table

end