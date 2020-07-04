# you need functionality from
# suffixtree
# structs
# ukkonen2

defmodule SuffixTree.Node do
  alias __MODULE__
  @moduledoc false

  @enforce_keys [
    # a single Node
    :parent,
    # If the strings are very long and unique, the string used as label could be replaced with label length, and then determined by working backwards from the upper end of the range in matches[0].
    :label,
    # A sorted list of tuples, in the form {hash, [ranges]}, where each listed range is of a length that equals the sum of all labels from root to the current Node.
    :matches,
    # a list of Nodes
    :children,
    # a single Node
    :link
  ]
  defstruct parent: nil,
            label: nil,
            matches: [],
            children: [],
            link: nil

  def root?(%Node{parent: parent}) do
    !parent
  end

  def leaf?(%Node{children: children}) do
    Enum.empty?(children)
  end

  def add_child(%Node{children: children} = parent, child) do
    child = %{child | parent: parent}
    new_children = [child | children]
    parent = %{parent | children: new_children}
    {:ok, parent}
  end

  # rework functions from here down
  def remove_child(%Node{children: children} = parent, child) do
    children = List.delete(children, child)
    parent = %{parent | children: children}
    {:ok, parent}
  end

  def get_child(children, hash) do
    Enum.find(children, fn child -> child == hash end)
  end

  def get_string(hash) do
    # look up the string by hash
  end

  def split_edge(node, new_node) do
    # ...
  end

  def skip_count(label) do
    # skips down the tree until we exhaust the label
  end

  def match(tree, substring) do
    # compare the first character of substring to the available child edge first chars of root (only one will match)
    # match:
    # compare the length of the substring to the edge that matches
    # if the substring is shorter than the edge, compare each character
    # if the characters match, return all leaves from that branch of the tree
    # if the characters don't match, return an empty list
    # if the substring is longer than the edge, compare only the last character of the edge to the character at length(edge) position in the substring
    # if the last character of the edge matches the nth character of the substring, begin your next comparison from the n + 1th character of the substring and repeat from the first character match above
    # when you reach a point where the substring is out of characters, or you reach a point where the nth character of the substring fails to match any branch off the node in question, then simply return all leaves
    # this needs work - you need to either point from each leaf to the parent string in the tree, or in a separate indexed list
    # no match:
    # return an empty list
  end

  def murmur(string) do
    Murmur.hash_x86_128(string)
  end
end
