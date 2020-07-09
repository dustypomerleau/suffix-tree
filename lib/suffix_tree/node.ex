# you need functionality from
# suffixtree
# structs
# ukkonen2

# import, alias, use

defmodule SuffixTree.Node do
  @moduledoc false

  alias __MODULE__
  use Puid

  @enforce_keys [:id, :children]

  defstruct id: nil,
            parent: nil,
            label: nil,
            leaves: [],
            children: [],
            link: nil

  @type t :: %Node{
          id: String.t(),
          parent: Node.t(),
          label: {String.t(), Range.t()},
          leaves: [{String.t(), integer()}],
          children: [Node.t()],
          link: Node.t()
        }

  def new_node() do
    %Node{
      id: generate(),
      parent: nil,
      label: nil,
      leaves: [],
      children: [],
      link: nil
    }
  end

  def root?(%{parent: parent}) do
    !parent
  end

  # only applies to leaf nodes, not those listed in the leaves field
  def leaf?(%{children: children}) do
    Enum.empty?(children)
  end

  def add_child(%{children: children} = parent, child) do
    {:ok, child} = add_parent(parent, child)
    children = [child | children] |> Enum.sort(Node)
    {:ok, %{parent | children: children}}
  end

  def add_parent(parent, child) do
    {:ok, %{child | parent: parent}}
  end

  # `compare/2 is used by `Enum.sort(list, Node)`
  def compare(%{label: label1} = _node1, %{label: label2} = _node2) do
    case {label1, label2} do
      {label1, label2} when label1 > label2 -> :gt
      {label1, label2} when label1 < label2 -> :lt
      _ -> :eq
    end
  end

  def remove_child(%{children: children} = parent, child) do
    children = List.delete(children, child)
    {:ok, %{parent | children: children}}
  end

  def get_child(children, hash) do
    Enum.find(children, fn child -> child == hash end)
  end
end
