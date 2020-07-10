# you need functionality from
# suffixtree
# structs
# ukkonen2

defmodule SuffixTree.Node do
  @moduledoc false

  alias __MODULE__
  use Puid

  @type t :: %__MODULE__{
          id: String.t(),
          # parent.id
          parent: String.t(),
          # {hash, range}
          label: {String.t(), Range.t()},
          # {hash, start_index}
          leaves: [{String.t(), integer()}],
          # [child.id]
          children: [String.t()],
          # node.id
          link: String.t()
        }

  @enforce_keys [:id, :children]
  defstruct id: nil,
            parent: nil,
            label: nil,
            leaves: [],
            children: [],
            link: nil

  # should we enforce the parent field and take parent as an arg here?
  def new_node() do
    %__MODULE__{
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

  def add_child(
        %{id: parent_id, children: children} = parent,
        %{id: child_id} = child
      ) do
    {:ok, child} = add_parent(parent_id, child)
    children = [child_id | children] |> Enum.sort()
    parent = %{parent | children: children}
    {:ok, parent, child}
  end

  def add_parent(parent_id, child) do
    {:ok, %{child | parent: parent_id}}
  end

  def remove_child(%{children: children} = parent, child_id) do
    children = List.delete(children, child_id)
    {:ok, %{parent | children: children}}
  end

  # # perhaps rewrite this if needed
  # def get_child(children, hash) do
  #   Enum.find(children, fn child -> child == hash end)
  # end

  # `compare/2 is used by `Enum.sort(list, Node)`
  # since you are sorting ids rather than nodes this function may not be needed
  def compare(%{label: label1} = _node1, %{label: label2} = _node2) do
    case {label1, label2} do
      {label1, label2} when label1 > label2 -> :gt
      {label1, label2} when label1 < label2 -> :lt
      _ -> :eq
    end
  end
end
