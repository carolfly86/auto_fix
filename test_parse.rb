#!/usr/bin/env ruby
require 'pg_query'
require 'trollop'
require 'pp'
require 'pg'
require 'yaml'
require 'json'
require 'pry'
Dir["lib/*"].each {|file| require_relative file }

opts = Trollop::options do
  banner "Usage: " + $0 + " --script [script] "
  opt :script, "location of sql script", :type => :string
  opt :expectation, "location of expectation file", :type => :string
end
#cfg = YAML.load_file( File.join(File.dirname(__FILE__), "config/default.yml") )
#conn = PG::Connection.open(dbname: cfg['default']['database'], user: cfg['default']['user'], password: cfg['default']['password'])

fqueryJson = JSON.parse(File.read("sql/#{opts[:script]}.json"))
tqueryJson = JSON.parse(File.read('sql/true.json'))

fQuery = fqueryJson['query']
f_pkList = fqueryJson['pkList']

fTable = 'f_result'
fqueryJson['table'] = fTable
DBConn.tblCreation(fTable, f_pkList, fQuery)

tQuery = tqueryJson['query']
t_pkList = tqueryJson['pkList']
tTable = 't_result'
tqueryJson['table'] = tTable
DBConn.tblCreation(tTable, t_pkList, tQuery)


fqueryJson['parseTree']= PgQuery.parse(fQuery).parsetree[0]
tqueryJson['parseTree']=PgQuery.parse(tQuery).parsetree[0]

pp fqueryJson['parseTree']

#
puts "similarity"
localizeErr = LozalizeError.new(fqueryJson,tqueryJson)
selectionErrList = localizeErr.selecionErr()
fqueryJson['score'] = localizeErr.getSuspiciouScore()

hc=HillClimbingAlg.new(fqueryJson,tqueryJson)
hc.hill_climbing(128)
return

# localizeErr.similarityBitMap()
#puts tQuery.query

# generate parse tree


# Auto fix using GA
# ga = GeneticAlg.new(ps)
# prog = ga.generate_random_program()

# psNew = ps
# psNew['SELECT']['whereClause'] = prog
# pp prog

# p ReverseParseTree.reverse(psNew)
#ga.generate_neighbor_program(prog)



#pp ps
#ReverseParseTree.reverse(ps)

# find projection error
#p fQuery.table


# projErrList = localizeErr.projErr()
# pp 'Projetion Error List:'
# pp projErrList


ps = PgQuery.parse(fQuery).parsetree[0]
#Fix join Error
psNew = AutoFix.JoinTypeFix(selectionErrList['JoinErr'],ps)
# Create test tbl after fixing join errors
fQueryNew = ReverseParseTree.reverse(psNew)
fTable = 'f_result_new'
p fQueryNew
query = QueryBuilder.create_tbl(fTable, f_pkList, fQueryNew)
DBConn.exec(query)

localizeErr_aftJoinFix = LozalizeError.new(fQueryNew, fTable, tTable)
selectionErrList_aftJoinFix = localizeErr_aftJoinFix.selecionErr()
pp selectionErrList_aftJoinFix

# # Auto fix using HB (only need in fixing where condition error)
# hb = HillClimbingAlg.new(ps)
# hb.generate_neighbor_program


# Auto fix using GA
#autoFix = GeneticAlg.new(ps.parsetree[0])