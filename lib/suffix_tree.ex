defmodule SuffixTree do
  @moduledoc false

  import SuffixTree.Node

  @type t :: %SuffixTree{
          id: String.t(),
          nodes: %{String.t() => Node.t()},
          strings: %{integer() => String.t()}
        }

  @enforce_keys [:id, :nodes, :strings]
  defstruct id: nil, nodes: %{}, strings: %{}

  @doc """
  Takes a map of strings in the form `%{hash => string}`, and returns a nodeless suffix tree that can be passed to `build_implicit/1` as the first step to building a suffix tree.
  """
  @spec new_tree(%{String.t() => String.t()}) :: SuffixTree.t()
  def new_tree(strings \\ %{}) do
    %SuffixTree{
      id: generate(),
      nodes: %{"root" => new_root()},
      strings: strings
    }
  end

  @doc """
  Takes a list of strings and returns a suffix tree struct for those strings, consisting of a map of tree nodes and a map of included strings. Each node has a Puid-generated `id` that can be referenced to store parent and child relationships in the nodes map. Non-cryptographic hashes are used to store node labels and tree leaves without repeatedly storing very long strings.
  """
  @spec build_tree([String.t()]) :: {:ok, SuffixTree.t()}
  def build_tree(string_list) do
    {:ok, strings} = build_strings(string_list)
    tree = new_tree(strings)
    {:ok, implicit_tree} = build_implicit(tree)
    {:ok, build_explicit(implicit_tree)}
  end

  @doc """
  Takes a list of strings and returns a map in the form:

  ```elixir
  %{Murmur3F_hash => string}
  ```

  The returned map is used as a lookup table by `build_tree/1`, during construction of the `nodes` map.
  """
  @spec build_strings([String.t()]) :: {:ok, %{integer() => String.t()}}
  def build_strings(string_list) do
    strings =
      Enum.into(
        string_list,
        %{},
        fn string -> {hash(string), string} end
      )

    {:ok, strings}
  end

  @doc """
  Builds an implicit suffix tree by iterating through its `strings` map and adding appropriate nodes to the `nodes` map. Returns the implicit tree, which can be transformed into an explicit tree by `build_explicit/1`.
  """
  @spec build_implicit(SuffixTree.t()) :: {:ok, SuffixTree.t()}
  def build_implicit(%{nodes: nodes, strings: strings} = tree) do
    nodes =
      Enum.reduce(
        strings,
        nodes,
        fn {hash, string}, nodes -> add_string(nodes, strings, hash, string) end
      )

    tree = %{tree | nodes: nodes}
    {:ok, tree}
  end

  # it may be that you need to add :last as part of every string addition, in which case build explicit doesn't really need to exist, but add string would need to have an add grapheme or codepoint for the normal ones, followed by one for add :last. So every string addition would then return an explicit tree. In that case you may be able to refactor build_implicIt and build_explicit into a single build_tree above.
  @spec build_explicit(SuffixTree.t()) :: {:ok, SuffixTree.t()}
  def build_explicit(%{nodes: nodes, strings: strings} = tree) do
    nodes = add_string(nodes, strings, :last)
    tree = %{tree | nodes: nodes}
    {:ok, tree}
  end

  def hash(string) do
    Murmur.hash_x86_128(string)
  end

  # so i think the answer is to move the addition of last inside add_string and call it after add grapheme or whatever you end up calling it.
  def add_string(nodes, strings, :last) do
    # special case
    {:ok, nodes}
  end

  def add_string(nodes, strings, hash, string) do
    # add the string to the tree
    {:ok, nodes}
  end

  def extend(grapheme) do
    # extend the suffix tree by grapheme
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

  def remove_node(node) do
    # remove the node
    # removing a string from the tree may be as simple as finding every use of that hash and deleting it, and then in a case where that leaves matches empty, delete the node
    # don't forget to check for root though, because matches there will be empty and we don't want to delete that
  end
end
