defmodule SuffixTree.Match do
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
    # {:ok, matches}
  end
end