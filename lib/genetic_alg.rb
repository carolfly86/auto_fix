
require 'jsonpath'
require_relative 'reverse_parsetree'
require_relative 'db_connection'
class GeneticAlg
# Genetic Programming in the Ruby Programming Language

# The Clever Algorithms Project: http://www.CleverAlgorithms.com
# (c) Copyright 2010 Jason Brownlee. Some Rights Reserved. 
# This work is licensed under a Creative Commons Attribution-Noncommercial-Share Alike 2.5 Australia License.
	def initialize(parseTree)
		@max_gens = 100
	    @max_depth = 7
	    @pop_size = 100
	    @bouts = 5
	    @p_repro = 0.08
	    @p_cross = 0.90
	    @p_mut = 0.02
	    @oprators = [:+, :-, :*, :/]
	    @ps = parseTree
	    @fromPT =  @ps['SELECT']['fromClause']
	    @relList = DBConn.fromRels(@fromPT)

	end


end


