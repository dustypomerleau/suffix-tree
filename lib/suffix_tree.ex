defmodule SuffixTree do
  @moduledoc false

  @doc """
  Takes a list of strings and returns a suffix tree for those strings, as well as a map that allows each string to be looked up by hash. Non-cryptographic hashes are used to store possible matches for each node in the tree without repeatedly storing very long strings.
  """
  def build_tree(strings) do
    # build a suffix tree from a list of strings
    # {:ok, tree, lookup}
  end

  def build_lookup(strings) do
    Enum.into(strings, %{}, fn string -> {hash(string), string} end)
  end

  def hash(string) do
    Murmur.hash_x86_128(string)
  end

  # probably separate out SuffixTree.Build and SuffixTree.Match
  def match(tree, substring) do
    # compare the first character of substring to the available child edge first chars of root (only one will match)
    # match:
    # compare the length of the substring to the edge that matches
    # if the substring is shorter than the edge, compare each character
    # if the characters match, return all leaves from that branch of the tree
    # if the characters don't match, return an empty list
    # if the substring is longer than the edge, compare only the last character of the edge to the character at length(edge) position in the substring
    # if the last character of the edge matches the nth character of the substring, begin your next comparison from the n + 1th character of the substring and repeat from the first character match above
    # when you reach a point where the substring is out of characters, or you reach a point where the nth character of the substring fails to match any branch off the node in question, then simply return all leaves
    # this needs work - you need to either point from each leaf to the parent string in the tree, or in a separate indexed list
    # no match:
    # return an empty list
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
