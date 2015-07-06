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

opts = Trollop::options do
  banner "Usage: " + $0 + " --script [script] "
  opt :script, "location of sql script", :type => :string
end
cfg = YAML.load_file( File.join(File.dirname(__FILE__), "config/default.yml") )

conn = PG::Connection.open(dbname: cfg['default']['database'], user: cfg['default']['user'], password: cfg['default']['password'])

fQuery = QueryT.new(opts[:script], 'f_result', cfg)
tQuery = QueryT.new('true.json', 't_result',cfg)

puts tQuery.query

# generate parse tree
ps = PgQuery.parse(fQuery.query)
#pp ps
#ReverseParseTree.reverse(ps.parsetree[0])


# find projection error
localizeErr = LozalizeError.new(fQuery,tQuery, cfg)
#projErrList = localizeErr.projErr()
selectionErrList = localizeErr.selecionErr()
pp selectionErrList

