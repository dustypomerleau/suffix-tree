defmodule SuffixTree.Node do
  @moduledoc false

  @enforce_keys [
    :label,
    :parent,
    :children,
    :link
  ]
  defstruct label: "",
            parent: nil,
            children: [],
            link: nil
end
