require 'rubytree'
require_relative 'reverse_parsetree'

class PredicateTree
  # def initialize(support,behavior)
  # end
  # attr_accessor :count, :content
  attr_reader :node_count, :pdtree, :branches, :branch_count, :nodes
  def initialize(type,is_new, test_id)
    @node_count = 0
    @branch_count=0
    #@wherePT=wherePT
    @type=type
    
    # @rootNode=Tree::TreeNode.new('root', '')
    @nqTblName = 'node_query_mapping'
    node_query_mapping_create() if is_new
    @test_id = test_id
    @branches = []
    @nodes = []
    #pdtree_construct(wherePT, @pdtree )
    # curNode = Tree::TreeNode.new(nodeName, '')    
  end

  def pdtree_construct(wherePT,curNode)
    logicOpr = wherePT.keys[0].to_s
    lexpr = wherePT[logicOpr]['lexpr']
    rexpr = wherePT[logicOpr]['rexpr']

    #p logicOpr
    if logicOpr == 'AEXPR AND' 
      lexprNode = pdtree_construct(lexpr,curNode) 
      rexprNode = pdtree_construct(rexpr,curNode)
      # p 'l'
      # lexprNode.print_tree
      # p 'r'
      # rexprNode.print_tree
      # p lexprNode.out_degree
      # p rexprNode.out_degree
      if ( lexprNode.out_degree>0 or rexprNode.out_degree>0 )
        structure_reform(lexprNode,rexprNode,curNode)
      else
        append_to_end(lexprNode,rexprNode)
        curNode<<lexprNode
      end
    # or operator are tested as a whole 
    elsif logicOpr == 'AEXPR OR'
      lexprNode = pdtree_construct(lexpr,curNode) 
      rexprNode = pdtree_construct(rexpr,curNode)
      #  p 'c'
      # curNode.print_tree
      # p 'l'
      # lexprNode.print_tree
      # p 'r'
      # rexprNode.print_tree
      curNode<<lexprNode unless curNode==lexprNode 
      curNode<<rexprNode unless curNode==rexprNode 
    else 
      @node_count=@node_count+1
      nodeName= "N#{@node_count}"
      h =  Hash.new
      h['query'] = ReverseParseTree.whereClauseConst(wherePT)
      # pp wherePT
      h['location'] = wherePT[logicOpr]['location']
      h['columns']=ReverseParseTree.columnsInPredicate(wherePT)
      h['suspicious_score'] = 0
      # pp h
      curNode=Tree::TreeNode.new(nodeName, h)
      # p @nqTblName

      @nodes << transfer_child_to_node(curNode)
      node_query_mapping_insert( nodeName,h['query'],h['location'],h['columns'],h['suspicious_score'])
    end
    #pp result.to_a
    curNode
  end

  def node_query_mapping_insert( nodeName,query,loc,columns, suspicious_score)
    columnsArray=columns.map{|c| "'"+c+"'"}.join(',')
    query = "INSERT INTO #{@nqTblName} values (#{@test_id} ,'#{nodeName}', '#{query.gsub(/'/,'\'\'')}',#{loc}, ARRAY[#{columnsArray}], #{suspicious_score} , '#{@type}' )"
    DBConn.exec(query)
  end
  def node_query_mapping_upd( nodeName,query)
    query = "UPDATE #{@nqTblName} SET #{query} where test_id=#{@test_id} and node_name = '#{nodeName}'"
    # pp query
    DBConn.exec(query)
  end
  def node_query_mapping_create()
    query =  "DROP TABLE if exists #{@nqTblName}; CREATE TABLE #{@nqTblName} (test_id int, node_name varchar(30), query text, location int, columns text[], suspicious_score int, type varchar(1));"
    DBConn.exec(query)
  end
  # append child to the end of tree
  def append_to_end(tree,child)
    deepChild=find_deepest_child(tree)
    deepChild<<child unless deepChild==child
    # p 'deepChild'
    # deepChild.print_tree
    # p 'tree'
    # tree.print_tree
    # tree
  end
  def find_deepest_child(tree)
    depth=0
    dpChild =tree.root
    tree.each_leaf do|node|
      # p 'node'
      # node.print_tree
      if node.node_depth >depth
        dpChild = node
      end
    end
    dpChild
  end
  # tree structure does not support multi parents
  # in order to present (a or b) and (c or d) 
  # we need to reform the structure to
  # (a and c) or (a and d) or (b and c) or (b and d)
  def structure_reform(lNode, rNode, curNode)

    lChildren=lNode.children.count() == 0? [lNode] : lNode.children
    rChildren=rNode.children.count() == 0? [rNode] : rNode.children
    count=0
    # p 'lnode'
    # pp lChildren
    # p 'rnode'
    # pp rChildren
    lChildren.each do |ln|
      rChildren.each do |rn|
        # p '--------------'
        # p 'ln'
        # ln.print_tree
        # p 'rn'
        # rn.print_tree
        phName="PH#{@branch_count}"
        ph =Tree::TreeNode.new(phName, '')
        ln_append=ln.detached_subtree_copy
        append_to_end(ln_append,rn)
        # p 'ln_append'
        ln_append.print_tree
        ph<<ln_append #unless curNode==newNode
        curNode<<ph
        # p 'ph'
        # ph.print_tree
        # p 'curNode'
        # curNode.print_tree

        br = Branch.new()
        br.name = phName
        br.nodes =[]
        @branches << br

        br.nodes<<transfer_child_to_node(ln_append)

        ln_append.children.each do |child|
          br.nodes<<transfer_child_to_node(child)
        end

        @branch_count=@branch_count+1
      end
    end

  end

  def transfer_child_to_node(child)
      nd = Node.new()
      nd.name=child.name
      nd.query = child.content['query']
      nd.location = child.content['location']
      nd.columns = child.content['columns']
      nd.suspicious_score = child.content['suspicious_score']
      nd
  end
  def predicateArrayGen(pdtree)
    predicateArry =Array.new()
     pdtree.children.each do |branch|
        currentNode = branch
        while currentNode.has_children?
          currentNode=currentNode.children[0]
          loc = currentNode.content['location']
          suspicious_score = currentNode.content['suspicious_score']
          element = predicateArry.find_hash('name',currentNode.name )
          node = Hash.new()
          if element.nil?
            node['name']=currentNode.name
            node.merge!(currentNode.content) 
            predicateArry <<node
          else
            element['suspicious_score']=element['suspicious_score']+suspicious_score
          end
        end
      end
    predicateArry
  end



end
