defmodule SuffixTree do
  @moduledoc false

  import SuffixTree.Node

  @type hash :: integer()
  @type index :: integer()
  @type n :: SuffixTree.Node.n()
  @type nid :: SuffixTree.Node.nid()
  @type stid :: String.t()

  @type st :: %SuffixTree{
          id: stid(),
          nodes: %{nid() => n()},
          strings: %{hash() => String.t()},
          current: {nid(), index()},
          explicit: nid(),
          phase: {index(), index()}
          # be sure to create the suffix link on explicit before reassigning explicit to the link target
        }

  @enforce_keys [:id, :nodes, :strings]
  defstruct [:id, :nodes, :strings, :current, :explicit, :phase]

  @doc """
  Takes a list of strings and returns a suffix tree struct for those strings, consisting of a map of tree nodes and a map of included strings.
  """
  @spec build_tree([String.t()]) :: st()
  def build_tree(string_list) do
    string_list |> new_tree() |> build_nodes()
  end

  @doc """
  Takes a list of strings, or a map of strings in the form `%{hash => string}`, and returns a nodeless suffix tree that can be passed to `build_nodes/1` to generate a true suffix tree.
  """
  @spec new_tree([String.t()]) :: st()
  @spec new_tree(%{hash() => String.t()}) :: st()
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
      explicit: "root",
      phase: {0, 0}
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
  @spec build_nodes(st()) :: st()
  def build_nodes(%{strings: strings} = tree) do
    Enum.reduce(
      strings,
      tree,
      fn {hash, string}, tree -> add_string(tree, hash, string) end
    )
  end

  @spec add_string(st(), String.t()) :: st()
  @spec add_string(st(), hash(), String.t()) :: st()
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
          phase: {phase, _extension}
        } = tree,
        hash,
        <<grapheme::utf8, rest::binary>> = _string
      ) do
    root = nodes["root"]
    matching_child_id = match_child(tree, root, <<grapheme::utf8>>)

    tree =
      case matching_child_id do
        nil ->
          new_child = %{new_node("root") | label: {hash, phase..-1}}
          {root, new_child} = add_child(root, new_child)
          nodes = Map.merge(nodes, %{"root" => root, new_child.id => new_child})

          %{
            tree
            | nodes: nodes,
              current: {new_child.id, cur_index + 1},
              explicit: new_child.id
          }

        # changing exp_node on an implicit match is unique to extension 0
        _child_id ->
          %{
            tree
            | current: {matching_child_id, cur_index + 1},
              explicit: matching_child_id
          }
      end

    # NOTE:
    # add_string should increment phase and reset extension before returning the tree
    # extend should update extension before returning the tree
    # extend :last should reset phase and extension before returning the tree
    # TODO: you need to add leaves as well as label
    tree = %{tree | phase: {phase + 1, 0}}
    add_string(tree, hash, rest)
  end

  def add_string(
        %{phase: {phase, _extension}} = tree,
        hash,
        <<grapheme::utf8, rest::binary>> = _string
      ) do
    tree = extend(tree, hash, <<grapheme::utf8>>)
    tree = %{tree | phase: {phase + 1, 0}}
    add_string(tree, hash, rest)
  end

  @spec extend(st(), hash(), :last) :: st()
  @spec extend(st(), hash(), String.t()) :: st()
  def extend(tree, hash, :last) do
    # faux extend the suffix tree by :last
    # in order to convert the implicit tree to an explicit one
    # must return the tree and reset the extension in prep for the next string
    %{tree | phase: {0, 0}}
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

  for a given string, first confirm that the string is present in the strings map - if not, add it - best way to do this is probably to privatize add_string/3 and expose only add_string/2

  start by checking children of the root for the first grapheme as the first character of their label

  if there is a match, make that node current and explicit, increment the index, increment the extension, and return the tree

  if there is no match, create a node, make its parent "root", add the grapheme to the label, add the node to root's children, set the new node to current and explicit, replace root and add the new node in nodes, add nodes and the mods to explicit/current to the tree, increment extension and return the tree

  move to checking the next grapheme

  start at current, check the current index on the label and compare to grapheme
  if there is a match, increment the index for current, explicit, and the extension. set cur_nid but not exp_node. return the tree

  if there is no match
  """
  # extend is complete when extension == phase
  # leaves are determined by extension, labels are determined by phase
  def extend(
        %{
          nodes: nodes,
          strings: strings,
          current: {cur_nid, cur_index},
          explicit: exp_node,
          phase: {phase, extension}
        } = tree,
        hash,
        grapheme
      ) do
    # extend by grapheme
    tree = %{tree | phase: {phase, extension + 1}}
    extend(tree, hash, grapheme)
  end

  @spec match_child(st(), n(), String.t()) :: nid() | nil
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
  @spec child_match?(st(), n(), String.t()) :: boolean()
  def child_match?(tree, node, grapheme) do
    first = get_label(tree, node, 0..0)
    first == grapheme
  end

  @doc """
  Takes a tree and a node, and returns the label on the node. An optional subrange may be given, for returning only a portion of the label (for example, up to the current index). Returns an empty string if the label is nil, or if the subrange is outside the range of the label.
  """
  # TODO: this throws when you pass it a label of nil
  # should we create a label on every new node, or handle the nil case?
  @spec get_label(st(), n(), Range.t()) :: String.t()
  def get_label(tree, node, subrange \\ 0..-1)

  def get_label(_tree, %{label: nil} = _node, _subrange), do: ""

  def get_label(
        %{strings: strings} = _tree,
        %{label: {hash, range_first.._range_last = range}} = _node,
        subrange_first..subrange_last = subrange
      ) do
    range =
      case subrange do
        0..-1 -> range
        _ -> (range_first + subrange_first)..(range_first + subrange_last)
      end

    String.slice(strings[hash], range)
  end

  # the tree has the node whose label we'll split as cur_nid
  # cur_index is where the mismatch occurred
  # first call new_node() and make the parent the same as cur_nid
  # on the parent, remove cur_nid from children and add new node to children (sort)
  # on cur_nid, change parent to new node, and change label to start at cur_index
  # on new node, add cur_nid to children (sort) - parent is already set - and set the label to {hash, phase..phase}
  # return the tree
  @spec split_edge(st(), hash(), String.t()) :: st()
  def split_edge(%{current: {cur_nid, cur_index}} = tree, hash, grapheme) do
    # ...
    tree
  end

  @doc """
  Takes a suffix tree, starts at the location given by `current`, climbing up the tree and accumulating the label, until it reaches a node with a suffix link. It then walks down, until the cumulative label is exhausted, returning that `{node, index}` as `current` on the new tree.
  TODO: if you skip count from a child of root, the algorithm will match the starting node. No good...
  up_walk seems to work, but down_walk does not
  this has something to do with following the same path right back down
  we need to fix the root case of build label so that it goes to the child of the next extension
  """
  @spec skip_count(st()) :: st()
  def skip_count(tree) do
    {tree, label} = up_walk(tree)
    down_walk(tree, label)
  end

  @doc """
  If the current node has a link, we get the sublabel up to the current index, and return the label, setting `current` to the `id` of the node from which we start the down-walk (at position `-1`). If the node has no link, we grab the label (up to `cur_index`), set the parent to `cur_nid` (this time with a `cur_index` of `-1`) and check again for a link by calling the function recursively. The label on parent will only be concatenated with the existing label if the parent has no link, otherwise we can simply return the tree, using the `link` value on `current` as the target `nid` for the downwalk.
  TODO:
    1. revisit doing this with IO lists or reduce
    2. clarify how we hold onto the origin of the suffix link if it's not kept as cur_nid (will it be explicit?)
  """
  @spec up_walk(st(), String.t()) :: {st(), String.t()}
  def up_walk(tree, label \\ "")

  def up_walk(%{current: {"root", _cur_index}} = tree, label) do
    # TODO: handle the case of empty string, as this will be a match error
    <<_first::utf8, label::binary>> = label
    {tree, label}
  end

  def up_walk(
        %{nodes: nodes, current: {cur_nid, cur_index}} = tree,
        label
      ) do
    current = nodes[cur_nid]

    {tree, label} =
      case current.link do
        nil ->
          label = get_label(tree, current, 0..cur_index) <> label
          parent_id = nodes[current.parent].id
          tree = %{tree | current: {parent_id, -1}}
          up_walk(tree, label)

        _ ->
          tree = %{tree | current: {current.link, -1}}
          {tree, label}
      end

    {tree, label}
  end

  @spec down_walk(st(), String.t()) :: st()
  def down_walk(tree, <<>>) do
    # This case should never occur, but if it does, just return the tree.
    tree
  end

  def down_walk(
        %{nodes: nodes, current: {cur_nid, _cur_index}} = tree,
        <<grapheme::utf8, _rest::binary>> = label
      ) do
    current = nodes[cur_nid]
    # TODO: this code throws if `match_child` returns `nil`
    # but this should raise as it indicates a malconstructed tree
    # by definition, the downwalk from a suffix link should match
    matching_child_id = match_child(tree, current, <<grapheme::utf8>>)
    current = nodes[matching_child_id]
    cur_len = String.length(get_label(tree, current))
    label_len = String.length(label)

    tree =
      cond do
        cur_len < label_len ->
          tree = %{tree | current: {current.id, -1}}
          label = String.slice(label, cur_len..-1)
          down_walk(tree, label)

        true ->
          # subtract 1 to make the index 0-based.
          %{tree | current: {current.id, label_len - 1}}
      end

    tree
  end

  @spec add_child(st(), n(), map()) :: st()
  def add_child(
        %{nodes: nodes} = tree,
        %{children: children} = parent,
        fields \\ %{}
      ) do
    child = Map.merge(new_node(parent.id), fields)
    children = [child.id | children] |> Enum.sort()
    parent = %{parent | children: children}
    %{tree | nodes: Map.merge(nodes, %{parent.id => parent, child.id => child})}
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
