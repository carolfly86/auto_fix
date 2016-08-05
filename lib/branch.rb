require_relative 'db_connection'

class Branch
	attr_accessor :name, :nodes

    def passed_nodes(pkCond, test_id, tuple_type)
        query = "select node_name from tuple_node_test_result where #{pkCond} and test_id = #{test_id} and type = '#{tuple_type}' and branch_name = '#{@name}'"
        res = DBConn.exec(query)
        targetNodes = res.map{|r| r['node_name']}
        # for missing tuples, if it exists in tuple_node_test_result 
        # it must be failed
        if tuple_type =='M'
            @nodes.find_all{|nd| !targetNodes.include?(nd.name) }
        # for unwanted tuples, if it exists in tuple_node_test_result 
        # it must be passed    
        elsif tuple_type =='U'
            @nodes.find_all{|nd| targetNodes.include?(nd.name) }
        end

    end
end 