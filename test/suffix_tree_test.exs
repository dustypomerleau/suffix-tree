defmodule SuffixTreeTest do
  use ExUnit.Case
  import SuffixTree.Node
  alias SuffixTree.Node

  doctest SuffixTree

  @node_1 %Node{
    label: nil,
    parent: nil,
    children: [],
    link: nil
  }

  @node_2 %Node{
    label: nil,
    parent: nil,
    children: [],
    link: nil
  }

  test "only a node without parent is root" do
    assert root?(@node_1) == true
  end
end
