defmodule SuffixTree.Node do
  @moduledoc false

  alias __MODULE__
  use Puid

  @type hash :: integer()
  @type nid :: String.t()
  @type index :: integer()

  @type n :: %Node{
          id: nid(),
          parent: nid() | nil,
          label: {hash(), Range.t()} | nil,
          leaves: %{hash() => index()} | nil,
          children: [nid()],
          link: nid() | nil
        }

  @enforce_keys [:id, :parent, :children]
  defstruct [:id, :parent, :label, :leaves, :children, :link]

  @spec new_node(nid(), [nid()]) :: n()
  def new_node(parent_id, children \\ []) do
    %Node{id: generate(), parent: parent_id, children: children}
  end

  @spec new_root() :: n()
  def new_root() do
    %Node{id: "root", parent: nil, children: []}
  end

  @spec root?(n()) :: boolean()
  def root?(%{parent: parent}) do
    !parent
  end

  # only applies to leaf nodes, not those listed in the leaves field
  @spec leaf?(n()) :: boolean()
  def leaf?(%{children: children}) do
    Enum.empty?(children)
  end

  # adding parent is still necessary, because we may be changing existing nodes when we split a label
  @spec add_child(n(), n()) :: {n(), n()}
  def add_child(
        %{id: parent_id, children: children} = parent,
        %{id: child_id} = child
      ) do
    child = add_parent(parent_id, child)
    children = [child_id | children] |> Enum.sort()
    parent = %{parent | children: children}
    {parent, child}
  end

  @spec add_parent(nid(), n()) :: n()
  def add_parent(parent_id, child) do
    %{child | parent: parent_id}
  end

  @spec remove_child(n(), nid()) :: n()
  def remove_child(%{children: children} = parent, child_id) do
    children = List.delete(children, child_id)
    %{parent | children: children}
  end

  @spec add_label(n(), hash(), Range.t()) :: n()
  def add_label(node, hash, range) do
    %{node | label: {hash, range}}
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
