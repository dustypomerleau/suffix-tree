defmodule SuffixTree do
  @moduledoc false
  # consider refactoring all functions that take a `n()` to take a `nid()`

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
            hash: hash() | nil,
            phase: index(),
            extension: index()
          },
          explicit: %{node: nid(), extension: index()} | nil
        }

  @enforce_keys :id
  defstruct [:id, :nodes, :strings, :current, :explicit]

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
        hash: nil,
        phase: 0,
        extension: 0
      },
      explicit: nil
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

  def add_suffix(tree, <<grapheme::utf8, rest::binary>> = _string) do
    tree = extend(tree, <<grapheme::utf8>>)
    add_suffix(tree, rest)
  end

  # you still haven't adequately addressed that rule 3 is a showstopper
  # when the grapheme matches you have to end the phase
  @spec extend(st(), :last) :: st()
  @spec extend(st(), String.t()) :: st()
  def extend(tree, :last) do
    # faux extend the suffix tree by :last
    # in order to convert the implicit tree to an explicit one
    # must return the tree and reset the extension in prep for the next string
    # approach:
    # we know that :last will never match a grapheme, so we aren't comparing graphemes at all
    # instead we simply need to note whether a grapheme is present at our current position
    # if a grapheme is present, split the label, and add a leaf to the new node (which will have a label of "", perhaps best represented by running off the end of the current string (for example, if the string is "string", then we could have a label of {hash("string"), 6..6}))
    # if the empty string is present instead of a grapheme, then we know we're at the end of the label and nothing needs to be done

    %{
      tree
      | current: %{
          node: "root",
          index: 0,
          hash: nil,
          phase: 0,
          extension: 0
        },
        explicit: nil
    }
  end

  # extension is complete after the extension where extension == phase
  # we have an issue here because we are incrementing phase twice
  # you increment phase here, but then you are incrementing it again in add_suffix after extend returns
  # makes more sense to do it here, I think
  def extend(
        %{
          current: %{phase: phase, extension: extension} = current,
          explicit: %{node: exp_nid, extension: exp_ext}
        } = tree,
        _grapheme
      )
      when extension > phase do
    %{
      tree
      | current: %{
          current
          | node: exp_nid,
            index: 1,
            phase: phase + 1,
            extension: exp_ext
        }
    }

    # The logic about index is this:
    # given our approach to labels, where we add the string to -1 at the time of node creation, then by definition the only explicit addition happens at index 0 on each node.
    # So that begs the question of whether we need to return to that node at all, since we are then sure we can implicitly add the next grapheme (since the value of explicit is always set for the string in question, and would be reset to `nil` before starting a new string)
    # but we need to still start from this node in order to perform skip_count, if it is the case that the node has no suffix link (which, by definition, if it is the most recently created node, then it will not)
    # so I propose we set the index to -1 on explicit, and capture the node's entire label if we need to skip count
    # the problem with that approach is that the grapheme you are currently up to is not the grapheme at -1, it's the grapheme at 1
    # but that assumes that explicit happened on the most recent phase, is it possible it didn't? think about this - in the meantime start from index 1
    # NOTE: we need to hold onto the value of extension at the time that we set explicit, because our starting point for the next phase is going to be that node (what index?) starting on that extension number
  end

  # leaves are determined by extension, labels are determined by phase
  def extend(
        %{
          nodes: nodes,
          current:
            %{
              node: cur_nid,
              index: cur_index,
              extension: extension
            } = current
        } = tree,
        grapheme
      ) do
    cur_node = nodes[cur_nid]
    cur_grapheme = get_label(tree, cur_node, cur_index)

    tree =
      tree
      |> match_grapheme(cur_grapheme, grapheme)
      # problem is right here - you can't follow the link if match_grapheme invokes rule 3, instead you have to start the next phase from the last explicit extension
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
      nil ->
        add_child(tree, cur_node)

      _ ->
        %{tree | current: %{current | node: matching_child_id, index: 0}}
    end
  end

  def match_grapheme(tree, cur_grapheme, grapheme) do
    cond do
      cur_grapheme == grapheme -> tree
      true -> split_edge(tree)
    end
  end

  @spec follow_link(st()) :: st()
  def follow_link(
        %{
          nodes: nodes,
          current: %{node: cur_nid} = current
        } = tree
      ) do
    cur_node = nodes[cur_nid]

    case cur_node.link do
      nil ->
        skip_count(tree)

      _ ->
        target_nid = nodes[cur_node.link].id
        # doublecheck whether this is the index you want after following the link
        # under what circumstances would you need to follow the link?
        %{tree | current: %{current | node: target_nid, index: -1}}
    end
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
    first = get_label(tree, node, 0)
    first == grapheme
  end

  @doc """
  Takes a tree and a node, and returns the label on the node. An optional index may be given, for returning the grapheme at a particular position on the label. Returns an empty string if the label is nil, or if the index is outside the range of the label.
  """
  @spec get_label(st(), n()) :: String.t()
  @spec get_label(st(), n(), index()) :: String.t()
  def get_label(_tree, %{label: nil} = _node), do: ""

  def get_label(%{strings: strings} = _tree, %{label: {hash, range}} = _node) do
    String.slice(strings[hash], range)
  end

  def get_label(_tree, %{label: nil} = _node, _index), do: ""

  def get_label(
        %{strings: strings} = _tree,
        %{label: {hash, first.._last = range}} = _node,
        index
      )
      when index >= 0 do
    cond do
      index <= Enum.count(range) - 1 ->
        String.at(strings[hash], first + index)

      true ->
        ""
    end
  end

  def get_label(
        %{strings: strings} = _tree,
        %{label: {hash, _first..last = range}} = _node,
        index
      )
      when index < 0 do
    label = String.slice(strings[hash], range)

    cond do
      abs(index) <= String.length(label) ->
        String.at(label, last + index + 1)

      true ->
        ""
    end
  end

  # the tree has the node whose label we'll split as cur_nid
  # cur_index is where the mismatch occurred
  # call add_child on nodes[nodes[cur_nid].parent]
  # capture the id of the new child node you create
  # on the parent, remove cur_nid from children
  # reassess:
  # on cur_nid, change parent to new node, and change label to start at cur_index
  # on new node, add cur_nid to children (sort) - parent is already set - and set the label to {hash, phase..phase}
  # return the tree
  # this isn't so simple
  # we need to create 2 nodes to split the edge
  # one of them has the label up to one short of the current index
  #
  @spec split_edge(st()) :: st()
  def split_edge(
        %{
          nodes: nodes,
          current: %{
            node: cur_nid,
            index: cur_index,
            hash: cur_hash,
            extension: extension
          }
        } = tree
      ) do
    %{label: {label_hash, first..last}} = downstream = nodes[cur_nid]
    parent = nodes[downstream.parent]

    tree =
      tree
      |> remove_child(parent, downstream.id)
      |> add_child(
        parent,
        %{
          label: {label_hash, first..(first + cur_index - 1)},
          leaves: %{cur_hash => extension},
          children: [downstream.id]
        }
      )

    %{nodes: nodes, current: %{node: cur_nid}} = tree

    downstream = %{
      downstream
      | parent: cur_nid,
        label: {label_hash, (first + cur_index)..last}
    }

    tree = %{tree | nodes: %{nodes | downstream.id => downstream}}
    add_child(tree, nodes[cur_nid])
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
    label =
      case label do
        <<>> -> label
        <<_first::utf8, rest::binary>> -> rest
      end

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
          cur_label = get_label(tree, cur_node)
          label = String.slice(cur_label, 0..cur_index) <> label
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
        %{nodes: nodes, current: %{node: cur_nid} = current} = tree,
        <<grapheme::utf8, _rest::binary>> = label
      ) do
    cur_node = nodes[cur_nid]
    matching_child_id = match_child(tree, cur_node, <<grapheme::utf8>>)

    tree =
      case matching_child_id do
        nil ->
          add_child(tree, cur_node)

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
              %{
                tree
                | current: %{current | node: cur_node.id, index: label_len - 1}
              }
          end
      end

    tree
  end

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
          %{label: {hash, phase..-1}, leaves: %{hash => extension}}

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
  def link(
        %{
          current: %{node: cur_nid, extension: extension},
          explicit: nil
        } = tree
      ) do
    %{tree | explicit: %{node: cur_nid, extension: extension}}
  end

  def link(
        %{
          nodes: nodes,
          current: %{node: cur_nid, extension: extension},
          explicit: %{node: exp_nid}
        } = tree
      ) do
    explicit = %{nodes[exp_nid] | link: cur_nid}

    %{
      tree
      | nodes: %{nodes | explicit.id => explicit},
        explicit: %{node: cur_nid, extension: extension}
    }
  end

  @spec remove_child(st(), n(), nid()) :: st()
  def remove_child(
        %{nodes: nodes} = tree,
        %{children: children} = parent,
        child_id
      ) do
    children = List.delete(children, child_id)
    parent = %{parent | children: children}
    %{tree | nodes: %{nodes | parent.id => parent}}
  end

  # @spec remove_string(st(), String.t()) :: st()
  # def remove_string(tree, string) do
  #   # removing a string from the tree may be as simple as
  #   # * iterate through each node
  #   # * delete the hash from leaves
  #   # * check for the hash on label
  #   # * if the hash is present on label, use another hash in leaves to create a new label
  #   # * if no other hash is present in leaves, you need to prepend the node's label to the children of the node (checking and adjusting ranges) and adjust the parent of the children to the node's parent before deleting it
  #   # * delete the string from `strings`
  #   tree
  # end

  @spec hash(String.t()) :: integer()
  def hash(string) do
    Murmur.hash_x86_128(string)
  end
end
