# The tree is implied via 2 data structures:
# 1. %{hash => string} AKA `strings`
# 2. %{id => node} AKA `nodes`
# you could include both of these maps inside a SuffixTree struct... hmm

defmodule SuffixTree do
  @moduledoc false

  use Puid

  @type t :: %__MODULE__{
          id: String.t(),
          nodes: %{String.t() => Node.t()},
          strings: %{String.t() => String.t()}
        }

  @enforce_keys [:id, :nodes, :strings]
  defstruct id: nil, nodes: %{}, strings: %{}

  @doc """
  Creates an empty SuffixTree struct that can be passed to `build_implicit/1` as the first step to building a suffix tree. `new_tree/1` is the usual form, and takes the strings you would like to include in the tree as a map in the form `%{hash => string}`.
  """
  @spec new_tree(none() | %{String.t() => String.t()}) :: __MODULE__.t()
  def new_tree() do
    %__MODULE__{id: generate(), nodes: %{}, strings: %{}}
  end

  def new_tree(strings) do
    %__MODULE__{id: generate(), nodes: %{}, strings: strings}
  end

  @doc """
  Takes a list of strings and returns a suffix tree struct for those strings, consisting of a map of tree nodes and a map of included strings. Each node has a Puid-generated `id` that can be referenced to store parent and child relationships in the nodes map. Non-cryptographic hashes are used to store node labels and tree leaves without repeatedly storing very long strings.
  """
  @spec build_tree([String.t()]) :: {:ok, SuffixTree.t()}
  def build_tree(string_list) do
    {:ok, strings} = build_strings(string_list)
    tree = new_tree(strings)
    {:ok, implicit_tree} = build_implicit(tree)
    {:ok, tree} = build_explicit(implicit_tree)
  end

  @doc """
  Takes a list of strings and returns a map in the form:

  ```elixir
  %{Murmur3F_hash_output => hashed_input_string}
  ```

  The returned map is used as a lookup table by `build_tree/1`, during construction of the `nodes` map.
  """
  @spec build_strings([String.t()]) :: {:ok, %{String.t() => String.t()}}
  def build_strings(string_list) do
    strings = Enum.into(string_list, %{}, fn string -> {hash(string), string} end)

    {:ok, strings}
  end

  @spec build_implicit(__MODULE__.t()) :: {:ok, __MODULE__.t()}
  def build_implicit(tree) do
    tree =
      Enum.each(
        tree.strings,
        fn {hash, string} -> add_string(tree, hash, string) end
      )

    {:ok, tree}
  end

  @spec build_explicit(__MODULE__.t()) :: {:ok, __MODULE__.t()}
  def build_explicit(tree) do
    {:ok, add_string(tree, :last)}
  end

  def hash(string) do
    Murmur.hash_x86_128(string)
  end

  # NOTE: you don't need to add any leaves for a given string until :last
  def add_string(tree, :last) do
    # special case
    {:ok, tree}
  end

  # TODO: this enum won't actually store to the variable
  def add_string(tree, hash, string) do
    # graphemes = String.graphemes(string)
    # tree = Enum.each(graphemes, fn grapheme -> extend(tree, string, grapheme) end)
    # tree = extend(tree, hash, string, :last)
    {:ok, tree}
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
