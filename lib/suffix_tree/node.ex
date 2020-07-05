# you need functionality from
# suffixtree
# structs
# ukkonen2

defmodule SuffixTree.Node do
  alias __MODULE__
  @moduledoc false

  # # enforcing keys means they can't be nil, consider whether any should be enforced at all
  # @enforce_keys [
  #   # a single Node
  #   :parent,
  #   # If the strings are very long and unique, the string used as label could be replaced with label length, and then determined by working backwards from the upper end of the range in matches[0].
  #   :label,
  #   # a sorted list of tuples, in the form {hash, [ranges], leaf}, where each listed range is of a length that equals the sum of all labels from root to the current Node
  #   # obviously leaf? of `true` is only for the last range in the list
  #   :matches,
  #   #
  #   :leaves,
  #   # a list of Nodes
  #   :children,
  #   # a single Node
  #   :link
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
    children = [child | children] |> Enum.sort()
    parent = %{parent | children: children}
    {:ok, parent}
  end

  def remove_child(%Node{children: children} = parent, child) do
    children = List.delete(children, child)
    parent = %{parent | children: children}
    {:ok, parent}
  end

  def get_child(children, hash) do
    Enum.find(children, fn child -> child == hash end)
  end
end
