# Esko Ukkonen's algorithm for building a suffix tree

1. If the algorithm is just beginning to add a string, start at the root. Otherwise, start from the leaf node for _S[j - 1..i]_ (set at the end of the last phase - see below). Whenever we add a new leaf, its label should be set to _p..m_, which can be calculated from the length of _1..m_, however it's not necessary to hold this length as a variable, given that Elixir allows `p..-1`. Just be careful using 0-based indices, given that `length/1` is 1-based.
1. For (_j = 1, i = 1_), simply add _i_ from the root according to the [extension rules](#Extension-rules-for-adding-character-(_i-+-1_)).
1. For (_i >= 2_), start at the _j - 1_ leaf node, and add (_i + 1_) to the label (this first step always follows rule 1).
1. If the current node has a suffix link, follow it, and add (_i + 1_) to the label on _s(v)_.
1. If the current node does not have a suffix link, go up one level to its parent (or the root).
1. Follow the parent's suffix link (or start from the root if the parent is the root), walk _gamma_ down from _s(v)_ using [the skip count algorithm](#Skip-count-algorithm), and add (_i + 1_) according to the rules.
1. If extension _j_ created a node while adding (_i + 1_), then extension _j + 1_ will also create one, so add the suffix link _v -> s(v)_ before moving on.
1. If rule 2 is invoked, you will create a leaf. The leaf will always be `j..-1`, but the node labels will need to be adjusted. We should be able to adjust only `p` on the 2 labels, as described above.
1. Repeat this pattern of going up and across the suffix link for _j = j - 1..i + 1_ (or until you invoke rule 3).
1. If rule 3 is invoked, end the phase.
1. Take note of _j_ when you hit rule 3. _j - 1_ is the last _explicit_ extension you did.
1. Start the next phase from the leaf node of extension _j - 1_.
1. When you complete phase _m_, perform a special extension, ensuring that a leaf exists for every location where `:last` would be placed. This extension is unique, because `:last` is not actually added to the tree, but the algorithm is performed as if were planning to add this unique final character.

## Extension rules for adding character (_i + 1_)

1. If _beta_ (_S[j..i]_) ends at a leaf node, add (_i + 1_) to the label.
1. If no path from _beta_ starts with (_i + 1_), either add a new child (if _beta_ ends at a node), or split the edge and add a child (if _beta_ ends in the edge).
1. If some path from _beta_ already starts with (_i + 1_) (in the edge, or as a child if _beta_ ends at a node), do nothing.

## Skip count algorithm

1. When walking down from s(v), if length(_gamma_) = _g_ is longer than length(label) = _g'_, skip to the next matching child node, set _g_ to _g - g'_, _h_ to _g' + 1_, and compare character _h_ of _gamma_. If it matches, repeat, until _g < g'_. Skip to character _g_ on the edge and quit.
