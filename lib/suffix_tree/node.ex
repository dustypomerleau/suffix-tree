defmodule SuffixTree.Node do
  alias __MODULE__
  @moduledoc false

  @enforce_keys [
    :label,
    :parent,
    :children,
    :link
  ]
  defstruct label: nil,
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
    Enum.find(children, fn child -> child.label == label end)
  end
end
