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
          current: %{
            node: nid(),
            index: index(),
            explicit: nid(),
            hash: hash(),
            phase: index(),
            extension: index()
          }
        }

  @enforce_keys :id
  defstruct [:id, :nodes, :strings, :current]

  # TODO: now that hash is on the tree, review whether we need to pass it as a param in each function or get it from the tree

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
      current: %{
        node: "root",
        index: 0,
        explicit: nil,
        hash: nil,
        phase: 0,
        extension: 0
      }
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

  TODO: Now that we're putting `hash` into `current`, is varying the arity still the best control flow here?
  """
  @spec build_nodes(st()) :: st()
  def build_nodes(%{strings: strings} = tree) do
    Enum.reduce(
      strings,
      tree,
      fn {hash, string}, tree ->
        tree = %{tree | current: %{hash: hash}}
        add_substring(tree, string)
      end
    )
  end

  @spec add_string(st(), String.t()) :: st()
  def add_string(%{strings: strings} = tree, string) do
    hash = hash(string)
    strings = Map.put_new(strings, hash, string)
    tree = %{tree | strings: strings, current: %{hash: hash}}
    add_substring(tree, string)
  end

  @spec add_substring(st(), String.t()) :: st()
  def add_substring(tree, <<>>) do
    extend(tree, :last)
  end

  def add_substring(
        %{
          nodes: nodes,
          current: %{
            node: "root",
            hash: hash,
            phase: phase,
            extension: extension
          }
        } = tree,
        <<grapheme::utf8, rest::binary>> = _string
      ) do
    root = nodes["root"]
    matching_child_id = match_child(tree, root, <<grapheme::utf8>>)

    tree =
      case matching_child_id do
        nil ->
          add_child(tree, root, %{
            label: {hash, phase..-1},
            leaves: [{hash, extension}]
          })

        # changing exp_node on an implicit match is unique to extension 0
        # TODO: pattern match extension 0 instead
        # this is broken thinking i think - why are you incrementing cur_index when you just switched current to the child? should be 0, no?
        _child_id ->
          %{
            tree
            | current: %{
                node: matching_child_id,
                index: 0,
                explicit: matching_child_id
              }
          }
      end

    # NOTE:
    # add_substring should increment phase and reset extension before returning the tree
    # extend should update extension before returning the tree
    # extend :last should reset phase and extension before returning the tree
    # TODO: you need to add leaves as well as label
    tree = %{tree | current: %{phase: phase + 1}}
    add_substring(tree, rest)
  end

  def add_substring(
        %{current: %{phase: phase}} = tree,
        <<grapheme::utf8, rest::binary>> = _string
      ) do
    tree = extend(tree, <<grapheme::utf8>>)
    tree = %{tree | current: %{phase: phase + 1, extension: 0}}
    add_substring(tree, rest)
  end

  @spec extend(st(), :last) :: st()
  @spec extend(st(), String.t()) :: st()
  def extend(tree, :last) do
    # faux extend the suffix tree by :last
    # in order to convert the implicit tree to an explicit one
    # must return the tree and reset the extension in prep for the next string
    %{
      tree
      | current: %{
          node: "root",
          index: 0,
          explicit: nil,
          hash: nil,
          phase: 0,
          extension: 0
        }
    }
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
          current: %{
            node: cur_nid,
            index: cur_index,
            explicit: exp_node,
            hash: hash,
            phase: phase,
            extension: extension
          }
        } = tree,
        grapheme
      ) do
    tree =
      case nodes[cur_nid].link do
        nil ->
          %{current: %{node: cur_nid, index: cur_index}} = skip_count(tree)

        _ ->
          current = nodes[cur_nid]
          target_nid = nodes[current.link].id

          %{current: %{node: cur_nid, index: cur_index}} = %{
            tree
            | current: %{node: target_nid, index: -1}
          }
      end

    # by definition, if there is a suffix link, we can't add to the label
    # so either there is a matching child or we add a child, full stop
    # in the case where there is no suffix link, and we get to the target node by calling skip_count, we need to make a comparison at that location
    # but we should only need to call skip count when we have just created a node (what other circumstance would not already have a link?)
    # so skip count needs to deal with the situation where we are one short of the desired length for the downwalk, but there is no matching child
    # every time we create a new node this will be likely (not guaranteed in a generalized tree) to happen
    current = nodes[cur_nid]
    cur_grapheme = get_label(tree, current, cur_index..cur_index)

    cond do
      is_nil(cur_index) ->
        matching_child_id = match_child(tree, current, grapheme)

      # add the grapheme
      cur_grapheme == grapheme ->
        nil
        # return
    end

    # check for equality at the new location
    # if equality is present
    tree = %{tree | current: %{extension: extension + 1}}
    extend(tree, grapheme)
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
  TODO: there is an issue here, where passing a subrange that is outside the actual range, can give you parts of the string that aren't actually in the label. For example get_label(tree, node, -1..-1) on a one-character label will still get the previous character in the string, even if that label isn't supposed to contain it. So we need a check that subrange is within the label somehow.
  """
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
  @spec split_edge(st(), String.t()) :: st()
  def split_edge(
        %{current: %{node: cur_nid, index: cur_index, hash: hash}} = tree,
        grapheme
      ) do
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

  def up_walk(%{current: %{node: "root"}} = tree, label) do
    # TODO: handle the case of empty string, as this will be a match error
    <<_first::utf8, label::binary>> = label
    {tree, label}
  end

  def up_walk(
        %{nodes: nodes, current: %{node: cur_nid, index: cur_index}} = tree,
        label
      ) do
    current = nodes[cur_nid]

    {tree, label} =
      case current.link do
        nil ->
          label = get_label(tree, current, 0..cur_index) <> label
          parent_id = nodes[current.parent].id
          tree = %{tree | current: %{node: parent_id, index: -1}}
          up_walk(tree, label)

        _ ->
          tree = %{tree | current: %{node: current.link, index: -1}}
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
        %{nodes: nodes, current: %{node: cur_nid}, hash: hash} = tree,
        <<grapheme::utf8, _rest::binary>> = label
      ) do
    current = nodes[cur_nid]

    # correct this so that the nil case for matching child id calls add_child(tree, parent, grapheme) which should be moved into suffix_tree from node
    # that way we are returning with the necessary node already in place
    matching_child_id = match_child(tree, current, <<grapheme::utf8>>)

    tree =
      case matching_child_id do
        nil ->
          # TODO: add label and leaves to the fields map using hash, phase, and extension
          add_child(tree, current, %{})

        _ ->
          current = nodes[matching_child_id]
          cur_len = String.length(get_label(tree, current))
          label_len = String.length(label)

          cond do
            cur_len < label_len ->
              tree = %{tree | current: %{node: current.id, index: -1}}
              label = String.slice(label, cur_len..-1)
              down_walk(tree, label)

            true ->
              # subtract 1 to make the index 0-based.
              %{tree | current: %{node: current.id, index: label_len - 1}}
          end
      end

    tree
  end

  # TODO: handle leaves - actually this would be passed in `fields`.
  @spec add_child(st(), n(), map()) :: st()
  def add_child(
        %{nodes: nodes} = tree,
        %{children: children} = parent,
        fields \\ %{}
      ) do
    child = Map.merge(new_node(parent.id), fields)
    parent = %{parent | children: [child.id | children] |> Enum.sort()}

    tree = %{
      tree
      | nodes:
          Map.merge(nodes, %{
            parent.id => parent,
            child.id => child
          }),
        current: %{node: child.id, index: 0}
    }

    link(tree)
  end

  @spec link(st()) :: st()
  def link(%{current: %{node: cur_nid, explicit: nil}} = tree) do
    %{tree | current: %{explicit: cur_nid}}
  end

  def link(
        %{
          nodes: nodes,
          current: %{node: cur_nid, explicit: exp_nid}
        } = tree
      ) do
    explicit = %{nodes[exp_nid] | link: cur_nid}

    %{
      tree
      | nodes: %{nodes | explicit.id => explicit},
        current: %{explicit: cur_nid}
    }
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
