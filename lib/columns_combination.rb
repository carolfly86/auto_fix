require_relative 'db_connection'
require_relative 'query_builder'

class Columns_Combination
	attr_reader :c_hash, :v_hash
    def initialize(columns)
        table = 'columns_combinations'

        pkList = 'ith_combination,int_presentation'
        cnt = columns.count()
        max = 2**cnt-1
        query = %Q(select 0::bit as processed,
        length(replace(generate_series::bit(#{cnt})::varchar(30),'0',''))::int as ith_combination,
        generate_series::bigint as int_presentation,
        generate_series::bit(#{cnt}) as bit_combination
        FROM generate_series(1,#{max});)
        # @parseTree = options.fetch(:parseTree,PgQuery.parse(@query).parsetree[0])
        DBConn.tblCreation(table, pkList, query)

        query = "create index idx_columns_combinations_processed on columns_combinations (processed)"
        DBConn.exec(query)
        @c_hash = Hash.new()
        @v_hash = Hash.new()
        columns.each_with_index do |c,idx|
            @c_hash[c.hash]=idx
            @v_hash[idx] = c
        end

    end
	def encode(column_set)
        val = 0
        column_set.each do |c|
            val = val + 2**@c_hash[c.hash]
        end
        val
        # val.to_s(2)
	end
    def decode(binary_string)
        reverse_string = binary_string.reverse
        positions = (0 ... reverse_string.length).find_all { |i| reverse_string[i] == '1' }
        # pp positions
        rst = []
        positions.each do |p|
            rst << @v_hash[p]
        end
        rst
    end
    def get_ith_combinations(i)
        query = "select bit_combination from columns_combinations where ith_combination = #{i} and processed = 0::bit"
        rst = DBConn.exec(query)
        col_combinations=[]
        rst.each do |r|
            col_combinations << decode(r['bit_combination'])
        end
        col_combinations
    end
    def delete(column_set)
        int_presentation = encode(column_set)
        ith_combination = column_set.count()
        query = "update columns_combinations set processed = 1::bit where ith_combination = #{ith_combination} and int_presentation = #{int_presentation}"
        # pp query
        DBConn.exec(query)
    end
    def get_max_ith_combination()
        query = "select max(ith_combination) as max from columns_combinations where processed = 0::bit"
        rst = DBConn.exec(query)
        rst[0]['max'].to_i
    end

    def reset_processed()
        query = "update columns_combinations set processed = 0::bit where processed = 1::bit"
        # pp query
        DBConn.exec(query)
    end
end