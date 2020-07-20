defmodule SuffixTree do
  @moduledoc false

  import SuffixTree.Node

  @type t :: %SuffixTree{
          id: String.t(),
          nodes: %{String.t() => Node.t()},
          strings: %{integer() => String.t()},
          extension: integer(),
          last_explicit: String.t()
        }

  @enforce_keys [:id, :nodes, :strings, :extension, :last_explicit]
  defstruct id: nil,
            nodes: %{},
            strings: %{},
            extension: 0,
            last_explicit: "root"

  @doc """
  Takes a list of strings and returns a suffix tree struct for those strings, consisting of a map of tree nodes and a map of included strings.
  """
  @spec build_tree([String.t()]) :: SuffixTree.t()
  def build_tree(string_list) do
    string_list |> new_tree() |> build_nodes()
  end

  @doc """
  Takes a list of strings, or a map of strings in the form `%{hash => string}`, and returns a nodeless suffix tree that can be passed to `build_nodes/1` to generate a true suffix tree.
  """
  @spec new_tree([String.t()]) :: SuffixTree.t()
  @spec new_tree(%{String.t() => String.t()}) :: SuffixTree.t()
  def new_tree(strings \\ %{})

  def new_tree(strings) when is_list(strings) do
    %SuffixTree{
      id: generate(),
      nodes: %{"root" => new_root()},
      strings: build_strings(strings),
      extension: 0,
      last_explicit: "root"
    }
  end

  def new_tree(strings) when is_map(strings) do
    %SuffixTree{
      id: generate(),
      nodes: %{"root" => new_root()},
      strings: strings,
      extension: 0,
      last_explicit: "root"
    }
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

  @spec add_string(SuffixTree.t(), String.t()) :: SuffixTree.t()
  @spec add_string(SuffixTree.t(), String.t(), String.t()) :: SuffixTree.t()

  def add_string(tree, string) do
    add_string(tree, hash(string), string)
  end

  def add_string(tree, hash, <<>>) do
    extend(tree, hash, :last)
  end

  def add_string(tree, hash, <<grapheme::utf8, rest::binary>> = _string) do
    tree = extend(tree, hash, grapheme)
    add_string(tree, hash, rest)
  end

  @spec extend(SuffixTree.t(), integer(), :last) :: SuffixTree.t()
  @spec extend(SuffixTree.t(), integer(), String.t()) :: SuffixTree.t()

  def extend(tree, hash, :last) do
    # faux extend the suffix tree by :last
    # in order to convert the implicit tree to an explicit one
    tree
  end

  def extend(tree, hash, grapheme) do
    node = tree.nodes[tree.last_explicit]
    label = get_label(tree, node)
    last = String.at(label, -1)

    case last do
      ^grapheme ->
        tree

      _ ->
        nil
        # add to the label, tweak relationships and follow the link, then repeat
        # return the tree
    end
  end

  @doc """
  Takes a tree and a node, and returns the label on the node.
  """
  @spec get_label(SuffixTree.t(), Node.t()) :: String.t()
  def get_label(tree, node) do
    {hash, range} = node.label
    label = tree.strings[hash] |> String.slice(range)
    label
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

  def remove_node(tree, node) do
    # remove the node
    tree
  end

  def remove_string(tree, string) do
    # removing a string from the tree may be as simple as
    # * iterate through each node
    # * delete the hash from leaves
    # * check for the hash on label
    # * if the hash is present on label, use another hash in leaves to create a new label
    # * if no other hash is present in leaves, you need to prepend the node's label to the children of the node (checking and adjusting ranges) and adjust the parent of the children to the node's parent before deleting it
    # * delete the string from `strings`
    tree
  end

  def hash(string) do
    Murmur.hash_x86_128(string)
  end
end
