require 'rubytree'
require_relative 'reverse_parsetree'

class PredicateTree
  # def initialize(support,behavior)
  # end
  # attr_accessor :count, :content
  attr_reader :count, :pdtree
  def initialize(wherePT)
    @count = 0
    @phcount=0
    # @rootNode=Tree::TreeNode.new('root', '')

    @pdtree =Tree::TreeNode.new('root', '')
    pdtree_construct(wherePT, @pdtree )
    @pdtree.print_tree
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
      p lexprNode.out_degree
      p rexprNode.out_degree
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
      @count=@count+1
      nodeName= "N#{@count}"
      h =  Hash.new
      h['query'] = ReverseParseTree.whereClauseConst(wherePT)
      # pp wherePT
      h['location'] = wherePT[logicOpr]['location']
      h['suspicious_score'] = 0
      # pp h
      curNode=Tree::TreeNode.new(nodeName, h)
    end
    #pp result.to_a
    curNode
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
        phName="PH#{@phcount}"
        ph =Tree::TreeNode.new(phName, '')
        ln_append=ln.detached_subtree_copy
        append_to_end(ln_append,rn)
        # p 'ln_append'
        # ln_append.print_tree
        ph<<ln_append #unless curNode==newNode
        curNode<<ph
        # p 'ph'
        # ph.print_tree
        # p 'curNode'
        # curNode.print_tree
        @phcount=@phcount+1
      end
    end

  end


end
