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
            explicit: nid() | nil,
            hash: hash() | nil,
            phase: index(),
            extension: index()
          }
        }

  @enforce_keys :id
  defstruct [:id, :nodes, :strings, :current]

  @doc """
  Takes a list of strings and returns a suffix tree containing those strings.
  """
  @spec build_tree([String.t()]) :: st()
  def build_tree(string_list) do
    string_list |> new_tree() |> build_nodes()
  end

  @doc """
  Takes a list of strings, or a map of `{hash, string}` pairs, and returns a nodeless suffix tree struct. This tree can then be passed to `build_nodes/1` to generate a true suffix tree.
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

  The returned map is used as a lookup table during construction and use of the suffix tree, allowing `{hash, range}` representations of labels and `{hash, index}` representations of leaves on each node.
  """
  @spec build_strings([String.t()]) :: %{hash() => String.t()}
  def build_strings(string_list) do
    Enum.into(string_list, %{}, fn string -> {hash(string), string} end)
  end

  @doc """
  Takes a suffix tree and uses its `strings` map to build its `nodes` map. Returns an explicit suffix tree that is ready for use.
  """
  @spec build_nodes(st()) :: st()
  def build_nodes(%{strings: strings, current: current} = tree) do
    Enum.reduce(
      strings,
      tree,
      fn {hash, string}, tree ->
        tree = %{tree | current: %{current | hash: hash}}
        add_suffix(tree, string)
      end
    )
  end

  @doc """
  Adds a new string to an existing suffix tree.
  """
  @spec add_string(st(), String.t()) :: st()
  def add_string(%{strings: strings, current: current} = tree, string) do
    hash = hash(string)
    # TODO: handle collisions
    tree = %{
      tree
      | strings: Map.put_new(strings, hash, string),
        current: %{current | hash: hash}
    }

    add_suffix(tree, string)
  end

  @doc """
  Runs recursively until all suffixes of a given string are added to the tree (either explicitly or implicitly).
  """
  @spec add_suffix(st(), String.t()) :: st()
  def add_suffix(tree, <<>>) do
    extend(tree, :last)
  end

  def add_suffix(
        %{current: %{phase: phase} = current} = tree,
        <<grapheme::utf8, rest::binary>> = _string
      ) do
    tree = extend(tree, <<grapheme::utf8>>)
    tree = %{tree | current: %{current | phase: phase + 1, extension: 0}}
    add_suffix(tree, rest)
  end

  @spec extend(st(), :last) :: st()
  @spec extend(st(), String.t()) :: st()
  def extend(%{current: current} = tree, :last) do
    # faux extend the suffix tree by :last
    # in order to convert the implicit tree to an explicit one
    # must return the tree and reset the extension in prep for the next string
    %{
      tree
      | current: %{
          current
          | node: "root",
            index: 0,
            explicit: nil,
            hash: nil,
            phase: 0,
            extension: 0
        }
    }
  end

  # extension is complete after the extension where extension == phase
  def extend(
        %{current: %{phase: phase, extension: extension}} = tree,
    # set the correct values for node, index, phase, extension before moving to the next grapheme by returning in add_suffix
    # NOTE: we need to hold onto the value of extension at the time that we set explicit, because our starting point for the next phase is going to be that node (what index?) starting on that extension number
    # so set node: to exp_nid and index to... 1? and extension to exp_extension, and phase to phase + 1
    tree

  # leaves are determined by extension, labels are determined by phase
  def extend(
        %{
            %{
              node: cur_nid,
              index: cur_index,
              explicit: exp_node,
              hash: hash,
    cur_node = nodes[cur_nid]
    cur_grapheme = get_label(tree, cur_node, cur_index..cur_index)

              phase: phase,
      tree
      |> match_grapheme(cur_grapheme, grapheme)
      |> follow_link()

    tree = %{
      tree
      | current: %{
          current
          | index: cur_index + 1,
            extension: extension + 1
        }
    }

    extend(tree, grapheme)
  end

  @spec match_grapheme(st(), String.t(), String.t()) :: st()
  def match_grapheme(
        %{current: %{node: cur_node} = current} = tree,
        <<>>,
        grapheme
      ) do
    matching_child_id = match_child(tree, cur_node, grapheme)

    case matching_child_id do
            } = current
        add_child(tree, cur_node)
        grapheme
      ) do
        %{tree | current: %{current | node: matching_child_id, index: 0}}
    end
  end
        nil ->
  def match_grapheme(tree, cur_grapheme, grapheme) do
    cond do
      cur_grapheme == grapheme -> tree
      true -> split_edge(tree, grapheme)
    end
          target_nid = nodes[cur_node.link].id

  def follow_link(%{nodes: nodes, current: %{node: cur_nid} = current} = tree) do
    # by definition, if there is a suffix link, we can't add to the label
    # in the case where there is no suffix link, and we get to the target node by calling skip_count, we need to make a comparison at that location
    case cur_node.link do
      nil ->
        skip_count(tree)
    cur_node = nodes[cur_nid]
      _ ->
        target_nid = nodes[cur_node.link].id
        # doublecheck whether this is the index you want after following the link
        %{tree | current: %{current | node: target_nid, index: -1}}
        matching_child_id = match_child(tree, cur_node, grapheme)
    end

    # check for equality at the new location
    # if equality is present
    tree = %{tree | current: %{current | extension: extension + 1}}
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

  Technically these conds are nowhere near total coverage.
  There are a lot of assumptions about the possible values that will be passed, particularly in negative ranges. But for now it is working.
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
      cond do
        Enum.count(subrange) <= Enum.count(range) and subrange_first >= 0 ->
      case subrange do
            subrange_first..-1 -> (range_first + subrange_first)..-1
        _ -> (range_first + subrange_first)..(range_first + subrange_last)
      end

        Enum.count(subrange) <= Enum.count(range) ->
          subrange

        true ->
          nil
  end

    case range do
      nil -> ""
      _ -> String.slice(strings[hash], range)
    end
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
        %{
          nodes: nodes,
          current: %{node: cur_nid, index: cur_index} = current
        } = tree,
        label
      ) do
    cur_node = nodes[cur_nid]

    {tree, label} =
      case cur_node.link do
        nil ->
          label = get_label(tree, cur_node, 0..cur_index) <> label
          parent_id = nodes[cur_node.parent].id
          tree = %{tree | current: %{current | node: parent_id, index: -1}}
          up_walk(tree, label)

        _ ->
          tree = %{tree | current: %{node: cur_node.link, index: -1}}
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
        %{nodes: nodes, current: %{node: cur_nid, hash: hash} = current} = tree,
        <<grapheme::utf8, _rest::binary>> = label
      ) do
    cur_node = nodes[cur_nid]

    # correct this so that the nil case for matching child id calls add_child(tree, parent, grapheme) which should be moved into suffix_tree from node
    # that way we are returning with the necessary node already in place
    matching_child_id = match_child(tree, cur_node, <<grapheme::utf8>>)

    tree =
      case matching_child_id do
        nil ->
          # TODO: add label and leaves to the fields map using hash, phase, and extension
          add_child(tree, cur_node, %{})

        _ ->
          cur_node = nodes[matching_child_id]
          cur_len = String.length(get_label(tree, cur_node))
          label_len = String.length(label)

          cond do
            cur_len < label_len ->
              tree = %{
                tree
                | current: %{current | node: cur_node.id, index: -1}
              }

              label = String.slice(label, cur_len..-1)
              down_walk(tree, label)

            true ->
              # subtract 1 to make the index 0-based.
              %{
                tree
                | current: %{
                    current
                    | node: cur_node.id,
                      index: label_len - 1
                  }
              }
          end
      end

    tree
  end

  # TODO: handle leaves - actually this would be passed in `fields`.
  @spec add_child(st(), n(), map()) :: st()
  def add_child(
        %{
          nodes: nodes,
          current: %{hash: hash, phase: phase, extension: extension} = current
        } = tree,
        %{children: children} = parent,
        fields \\ %{}
      ) do
    fields =
      cond do
        map_size(fields) == 0 ->
          %{label: {hash, phase..phase}, leaves: %{hash => extension}}

        true ->
          fields
      end

    child = Map.merge(new_node(parent.id), fields)
    parent = %{parent | children: [child.id | children] |> Enum.sort()}

    tree = %{
      tree
      | nodes: Map.merge(nodes, %{parent.id => parent, child.id => child}),
        current: %{current | node: child.id, index: 0}
    }

    link(tree)
  end

  @spec link(st()) :: st()
  def link(%{current: %{node: cur_nid, explicit: nil} = current} = tree) do
    %{tree | current: %{current | explicit: cur_nid}}
  end

  def link(
        %{
          nodes: nodes,
          current: %{node: cur_nid, explicit: exp_nid} = current
        } = tree
      ) do
    explicit = %{nodes[exp_nid] | link: cur_nid}

    %{
      tree
      | nodes: %{nodes | explicit.id => explicit},
        current: %{current | explicit: cur_nid}
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
