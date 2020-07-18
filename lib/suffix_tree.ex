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
  Takes a list of strings and returns a suffix tree struct for those strings, consisting of a map of tree nodes and a map of included strings.
  """
  @spec build_tree([String.t()]) :: SuffixTree.t()
  def build_tree(string_list) do
    string_list |> build_strings() |> new_tree() |> build_nodes()
  end

  @doc """
  Takes a list of strings and returns a map in the form:

  ```elixir
  %{Murmur3F_hash => string}
  ```

  The returned map is used as a lookup table during construction and use of the suffix tree, allowing `{hash, index/range}` representations of labels and leaves on each node.
  """
  @spec build_strings([String.t()]) :: %{integer() => String.t()}
  def build_strings(string_list) do
    Enum.into(string_list, %{}, fn string -> {hash(string), string} end)
  end

  @doc """
  Takes a map of strings in the form `%{hash => string}`, and returns a nodeless suffix tree that can be passed to `build_nodes/1` to generate a true suffix tree.
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
  Takes a suffix tree and uses its `strings` map to build its `nodes` map. This is typically done with the nodeless tree returned by `new_tree/1`, but can also be done with an existing tree, where new strings have been added to its `strings` map, and corresponding nodes must be created. Returns an explicit suffix tree that is ready for use.
  """
  @spec build_nodes(SuffixTree.t()) :: SuffixTree.t()
  def build_nodes(%{strings: strings} = tree) do
    Enum.reduce(
      strings,
      tree,
      fn {hash, string}, tree -> add_string(tree, hash, string) end
    )
  end

  @spec add_string(
          SuffixTree.t(),
          String.t(),
          integer(),
          String.t()
        ) :: SuffixTree.t()
  def add_string(tree, jm1_node \\ "root", hash, string)

  def add_string(tree, jm1_node, hash, <<>>) do
    extend(tree, jm1_node, hash, :last)
  end

  def add_string(
        tree,
        jm1_node,
        hash,
        <<grapheme::utf8, rest::binary>> = string
      ) do
    {tree, jm1_node} = extend(tree, jm1_node, hash, grapheme)
    add_string(tree, jm1_node, hash, rest)

    # when this loop finishes, this function will return the tree because extend/4(..., :last) (and therefore add_string/4(..., :last)) returns only the tree
  end

  @spec extend(
          SuffixTree.t(),
          String.t(),
          integer(),
          String.t()
        ) :: {SuffixTree.t(), String.t()}
  def extend(tree, jm1_node \\ "root", hash, grapheme)

  def extend(tree, jm1_node, hash, :last) do
    # faux extend the suffix tree by :last
    # in order to convert the implicit tree to an explicit one
    # this should return the tree only, which should result in add_string returning only the tree, as it's called last.
    # However this needs to be clarified, because perhaps we need to return the same type from each clause?
  end

  def extend(tree, jm1_node, hash, grapheme) do
    # add the grapheme and return the new tree and new jm1
    {tree, jm1_node}
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

  def hash(string) do
    Murmur.hash_x86_128(string)
  end
end
