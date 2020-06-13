defmodule SuffixTree.Node do
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

  def root?(%{parent: parent}) do
    !parent
  end

  def leaf?(%{children: children}) do
    Enum.empty?(children)
  end

  def add_child(%{children: children} = parent, child) do
    child = %{child | parent: parent}
    parent = %{children: [child | children]}
    {:ok, parent}
  end

  def remove_child(%{children: children} = parent, label) do
    child = get_child(children, label)
    children = List.delete(children, child)
    parent = %{parent | children: children}
    {:ok, parent}
  end

  def get_child(children, label) do
    Enum.find(children, fn child -> child.label == label end)
  end
end
