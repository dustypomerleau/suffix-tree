defmodule SuffixTree do
  @moduledoc false

  alias SuffixTree.Node
  import SuffixTree.Node

  @type hash :: integer()
  @type id :: String.t()
  @type index :: integer()

  @type t :: %SuffixTree{
          id: SuffixTree.id(),
          nodes: %{Node.id() => Node.t()},
          strings: %{hash() => String.t()},
          current: {Node.id(), index()},
          explicit: {Node.id(), index()},
          extension: index()
          # be sure to create the suffix link on explicit before reassigning explicit to the link target
        }

  @enforce_keys [:id, :nodes, :strings]
  defstruct [:id, :nodes, :strings, :current, :explicit, :extension]

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
  @spec new_tree(%{hash() => String.t()}) :: SuffixTree.t()
  def new_tree(strings \\ %{}) do
    %SuffixTree{
      id: generate(),
      nodes: %{"root" => new_root()},
      strings:
        cond do
          is_list(strings) -> build_strings(strings)
          is_map(strings) -> strings
        end,
      current: {"root", 0},
      explicit: {"root", 0},
      extension: 0
    }
  end

  @doc """
  Takes a list of strings and returns a map in the form:

  ```elixir
  %{Murmur3F_hash => string}
  ```

  The returned map is used as a lookup table during construction and use of the suffix tree, allowing `{hash, index/range}` representations of labels and leaves on each node.
  """
  @spec build_strings([String.t()]) :: %{hash() => String.t()}
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
  @spec add_string(SuffixTree.t(), hash(), String.t()) :: SuffixTree.t()
  def add_string(%{strings: strings} = tree, string) do
    hash = hash(string)
    strings = Map.put_new(strings, hash, string)
    tree = %{tree | strings: strings}
    add_string(tree, hash, string)
  end

  def add_string(tree, hash, <<>>) do
    extend(tree, hash, :last)
  end

  def add_string(
        %{
          nodes: nodes,
          current: {"root", cur_index},
          explicit: {_exp_node, exp_index},
          extension: extension
        } = tree,
        hash,
        <<grapheme::utf8, rest::binary>> = _string
      ) do
    root = nodes["root"]
    matching_child_id = match_child(tree, root, <<grapheme::utf8>>)

    tree =
      case matching_child_id do
        nil ->
          new_child = new_node("root", [])
          {root, new_child} = add_child(root, new_child)
          new_child = %{new_child | label: {hash, extension..extension}}
          nodes = Map.merge(nodes, %{"root" => root, new_child.id => new_child})

          %{
            tree
            | nodes: nodes,
              current: {new_child.id, cur_index + 1},
              explicit: {new_child.id, exp_index + 1},
              extension: extension + 1
          }

        # changing explicit: on an implicit match is unique to root
        _child_id ->
          %{
            tree
            | current: {matching_child_id, cur_index + 1},
              explicit: {matching_child_id, exp_index + 1},
              extension: extension + 1
          }
      end

    add_string(tree, hash, rest)
  end

  def add_string(
        %{strings: strings} = tree,
        hash,
        <<grapheme::utf8, rest::binary>> = _string
      ) do
    tree = extend(tree, hash, <<grapheme::utf8>>)
    add_string(tree, hash, rest)
  end

  @spec extend(SuffixTree.t(), hash(), :last) :: SuffixTree.t()
  @spec extend(SuffixTree.t(), hash(), String.t()) :: SuffixTree.t()
  def extend(tree, hash, :last) do
    # faux extend the suffix tree by :last
    # in order to convert the implicit tree to an explicit one
    # must return the tree
    tree
  end

  @doc """
  fakedoc

  update explicit whenever you
  1. create a new node
  1. jump to a child of last explicit to find your match (this works from root also)
  update the index whenever you
  1. first add a grapheme (even if implicitly) - if the addition is implicit, it will be a show stopper anyway, so you are just incrementing the position on the label for your next comparison
  you can determine if you are first adding a grapheme by whether extension is 0
  the corollary to that is that you have to increment extension

  each call to extend is a phase
  which means that you need to recursively call extend while updating the state params on the tree - including incrementing extension from 0..m over the course of adding a particular grapheme

  ---

  for a given string, first confirm that the string is present in the strings map - if not, add it

  start by checking children of the root for the first grapheme as the first character of their label

  if there is a match, make that node current and explicit, increment the index, increment the extension, and return the tree

  if there is no match, create a node, make its parent "root", add the grapheme to the label, add the node to root's children, set the new node to current and explicit, replace root and add the new node in nodes, add nodes and the mods to explicit/current to the tree, increment extension and return the tree

  move to checking the next grapheme

  start at current, check the current index on the label and compare to grapheme
  if there is a match, increment the index and the extension and return the tree

  if there is no match
  """
  def extend(
        %{
          nodes: nodes,
          strings: strings,
          current: {cur_node, cur_index},
          explicit: {exp_node, exp_index},
          extension: extension
        } = tree,
        hash,
        grapheme
      ) do
    # extend by grapheme
    tree
  end

  @spec match_child(SuffixTree.t(), Node.t(), String.t()) :: Node.id() | nil
  def match_child(
        %{nodes: nodes} = tree,
        %{children: children} = _node,
        grapheme
      ) do
    Enum.find(
      children,
      fn child_id ->
        child = nodes[child_id]
        child_match?(tree, child, grapheme)
      end
    )
  end

  @doc """
  Returns a boolean, indicating whether the first grapheme in a node's label matches the given grapheme.
  """
  @spec child_match?(SuffixTree.t(), Node.t(), String.t()) :: boolean()
  def child_match?(tree, node, grapheme) do
    <<first::utf8, _rest::binary>> = get_label(tree, node)
    <<first::utf8>> == grapheme
  end

  @doc """
  Takes a tree and a node, and returns the label on the node.
  """
  # TODO: this throws when you pass it a label of nil
  # should we create a label on every new node, or handle the nil case?
  @spec get_label(SuffixTree.t(), Node.t()) :: String.t()
  def get_label(%{strings: strings} = _tree, %{label: {hash, range}} = _node) do
    String.slice(strings[hash], range)
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
