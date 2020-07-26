defmodule SuffixTree do
  @moduledoc false

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
      current: "root",
      explicit: nil,
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
  def add_string(tree, string) do
    add_string(tree, hash(string), string)
  end

  def add_string(tree, hash, <<>>) do
    extend(tree, hash, :last)
  end

  def add_string(
        %{strings: strings} = tree,
        hash,
        <<grapheme::utf8, rest::binary>> = string
      ) do
    case strings[hash] do
      nil ->
        strings = %{strings | hash => string}
        tree = %{tree | strings: strings}
        add_string(tree, hash, string)

      _ ->
        tree = extend(tree, hash, grapheme)
        add_string(tree, hash, rest)
    end
  end

  @spec extend(SuffixTree.t(), hash(), :last) :: SuffixTree.t()
  @spec extend(SuffixTree.t(), hash(), String.t()) :: SuffixTree.t()
  def extend(tree, hash, :last) do
    # faux extend the suffix tree by :last
    # in order to convert the implicit tree to an explicit one
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
  start at the current node, check the new index on the label and compare
  if there is a match, increment the index and the extension and return the tree.
  if there is no match
  """
  def extend(
        %{nodes: nodes, last_explicit: last_explicit} = tree,
        hash,
        grapheme
      ) do
    {last_node, last_index} = last_explicit
    node = nodes[last_node]
    # perhaps move below case
    # %{id: id, children: children} = node
    label = get_label(tree, node)
    last = String.at(label, -1)

    # you need to address this - you don't want the last character in the label, you want the character at last_index + 1

    node =
      case last do
        # last character of "" is nil, but last character of nil throws, so perhaps default to empty string when there is no label
        nil ->
          match_child(node, grapheme)

        # return the matching child node if present
        ^grapheme ->
          node

        # if the grapheme is already last on the node's label
        # return the node unchanged
        _ ->
          nil
      end

    # address a possible nil node
    # because either there are no children or no matches
    # if you create a new node, then add the suffix link to last_explicit before setting the new node to last_explicit

    #   "root" ->
    #     [node] =
    #       Enum.filter(
    #         children,
    #         fn child -> (get_label(tree, child) |> String.at(0)) == grapheme end
    #       )
    #   case node
    # end

    # case {last, %{id: id, children: children} = node} do
    #   {_grapheme, "root"} ->
    #     [node] =
    #       Enum.filter(
    #         children,
    #         fn child -> first = get_label(tree, child) |> String.at(0) end
    #         case first do
    #           ^grapheme ->

    #         end
    #         )

    # handle root case
    # enum through children
    # look for grapheme as the first character of label
    # if you find it, set last_explicit to that node's id
    # if you don't find it
    # create a new child node
    # list it as child on root
    # list root as its parent
    # add grapheme to the label in the form {hash, range}
    # set last_explicit to the new node's id
    # return the tree
    # {^grapheme, id} ->
    # tree

    # _ ->
    # nil
    # add to the label, tweak relationships and follow the link, increment j, etc. then repeat
    # return the tree
    # end
  end

  def match_child(node, grapheme) do
    # send back the child node whose label first char matches grapheme (or nil)
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
