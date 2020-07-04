defmodule SuffixTreeTest do
  use ExUnit.Case
  import SuffixTree.Node
  alias SuffixTree.Node

  doctest SuffixTree

  @node_1 %Node{
    parent: nil,
    label: nil,
    matches: [],
    children: [],
    link: nil
  }

  @node_2 %Node{
    parent: nil,
    label: nil,
    matches: [],
    children: [],
    link: nil
  }

  test "only a node without parent is root" do
    assert root?(@node_1) == true
  end

  test "murmur returns a hash" do
    hash = murmur("a sample string") |> to_string()
    assert Regex.match?(~r/\d{36,40}/, hash)
  end
end
