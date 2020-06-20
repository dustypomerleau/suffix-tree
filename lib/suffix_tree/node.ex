# you need functionality from
# suffixtree
# structs
# ukkonen2

defmodule SuffixTree.Node do
  alias __MODULE__
  @moduledoc false

  @enforce_keys [
    # the string of interest (index will be in a sorted list)
    # you will need to update the index field in each struct with its index when you sort, or use unique ids/hashes and sort by hash during build
    :index,
    # use a range for label to be applied to the string of interest
    :label,
    :parent,
    :children,
    :link
  ]
  defstruct index: nil,
            label: nil,
            parent: nil,
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
    parent = %{children: [child | children]}
    {:ok, parent}
  end

  def remove_child(%Node{children: children} = parent, label) do
    child = get_child(children, label)
    children = List.delete(children, child)
    parent = %{parent | children: children}
    {:ok, parent}
  end

  def get_child(children, label) do
    Enum.find(children, fn child -> get_label(child) == label end)
  end

  def get_label(%Node{index: index, label: label}) do
    # look up the label by index
    # take the range given by label
  end

  def split_edge(node, new_node) do
    # ...
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
    # no match:
    # return an empty list
  end
end
