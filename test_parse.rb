#!/usr/bin/env ruby
require 'pg_query'
require 'trollop'
require 'pp'
require 'pg'
require 'yaml'
require 'json'
require_relative 'lib/query_t'
require_relative 'lib/localizeError'
require_relative 'lib/reverse_parsetree'
require_relative 'lib/genetic_alg'
require_relative 'lib/autofix'

opts = Trollop::options do
  banner "Usage: " + $0 + " --script [script] "
  opt :script, "location of sql script", :type => :string
end
#cfg = YAML.load_file( File.join(File.dirname(__FILE__), "config/default.yml") )
#conn = PG::Connection.open(dbname: cfg['default']['database'], user: cfg['default']['user'], password: cfg['default']['password'])


fqueryJson = JSON.parse(File.read("sql/#{opts[:script]}"))
tqueryJson = JSON.parse(File.read('sql/true.json'))

fQuery = QueryT.new(fqueryJson, 'f_result')
tQuery = QueryT.new(tqueryJson, 't_result')

puts tQuery.query

# generate parse tree
ps = PgQuery.parse(fQuery.query).parsetree[0]

# Auto fix using GA
ga = GeneticAlg.new(ps)
prog = ga.generate_random_program()
psNew = ps
psNew['SELECT']['whereClause'] = prog
pp prog
p ReverseParseTree.reverse(psNew)
#pp ps
#ReverseParseTree.reverse(ps)

# find projection error
# localizeErr = LozalizeError.new(fQuery,tQuery, ps)
# projErrList = localizeErr.projErr()
# pp projErrList
#  selectionErrList = localizeErr.selecionErr()
#  pp selectionErrList

# psNew = AutoFix.JoinTypeFix(selectionErrList['JoinErr'],ps)
# fQueryNew = ReverseParseTree.reverse(psNew)
# f_pkList = fqueryJson['pkList']
# fQueryNewJson = {:query => fQueryNew , :pkList => f_pkList}.to_json
# localizeErr_aftJoinFix = LozalizeError.new(fQuery,tQuery, psNew)
# selectionErrList_aftJoinFix = localizeErr_aftJoinFix.selecionErr()
# pp selectionErrList_aftJoinFix



# Auto fix using GA
#autoFix = GeneticAlg.new(ps.parsetree[0])