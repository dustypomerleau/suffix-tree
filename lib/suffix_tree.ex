defmodule SuffixTree do
  @moduledoc false

  @doc """
  Takes a list of strings and returns a suffix tree for those strings, as well as a map that allows each string to be looked up by hash. Non-cryptographic hashes are used to store possible matches for each node in the tree without repeatedly storing very long strings.
  """
  def build_tree(strings) do
    # build a suffix tree from a list of strings
    {:ok, tree, lookup}
  end

  def build_lookup(strings) do
    Enum.into(strings, %{}, fn string -> {hash(string), string} end)
  end

  def hash(string) do
    Murmur.hash_x86_128(string)
  end
end
