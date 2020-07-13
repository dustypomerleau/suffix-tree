# Esko Ukkonen's algorithm for building a suffix tree

1. If the algorithm is just beginning to add a string, start at the root. Otherwise, start from the node whose label contains the last character of extension 1 of phase _i_ (the leaf node for _S[1..i]_, referred to here as the _j1_ node). Each phase would need to return its _j1_ node for use by the next phase, phase (_i + 1_), but since this will always be a leaf, we can simply hold a reference to this node for all phases on a given string.
FIX:
In addition, when we add leaves to this node (or nodes in future extensions), we can set the label to `p..e`, instead of `p..q`. `e`'s value is "the current end," and is stored globally and incremented for each extension. Then you only need to add the actual value when you reach rule 2 or 3.
WHY can't I just automatically set a newly created leaf to `j..m - 1`? This seems like it should be fine, but test. Perhaps incrementing _e_ until you reach _m_ is felt more efficient than calculating _m_ ahead of time for large strings, but the performance hit should be minimal.
1. For (_j = 1, i = 1_), simply add _i_ from the root according to the [extension rules](#Extension-rules-for-adding-character-(_i-+-1_)).
1. For (_i >= 2_), start at the _j1_ node, and add (_i + 1_) to the label (this first step always follows rule 1).
1. If the current node has a suffix link, follow it, and add (_i + 1_) to the label on _s(v)_.
1. If the current node does not have a suffix link, go up one level to its parent (or the root).
1. Follow the parent's suffix link (or start from the root if the parent is the root), walk _gamma_ down from _s(v)_ using [the skip count algorithm](#Skip-count-algorithm), and add (_i + 1_) according to the rules.
1. If extension _j_ created a node while adding (_i + 1_), then extension _j + 1_ will also create one, so add the suffix link _v -> s(v)_ before moving on.
1. Repeat for _j = 1..i + 1_.
1. Start a new phase at the _j1_ node for the previous phase. WAIT - I think the trick starts here.
1. When you complete phase _m_, perform a special extension, ensuring that a leaf exists for every location where `:last` would be placed. This extension is unique, because `:last` is not actually added to the tree, but the algorithm is performed as if were planning to add this unique final character.

## Extension rules for adding character (_i + 1_)

1. If _beta_ (_S[j..i]_) ends at a leaf node, add (_i + 1_) to the label.
1. If no path from _beta_ starts with (_i + 1_), either add a new child (if _beta_ ends at a node), or split the edge and add a child (if _beta_ ends in the edge).
1. If some path from _beta_ already starts with (_i + 1_) (in the edge, or as a child if _beta_ ends at a node), do nothing.

## Skip count algorithm

1. When walking down from s(v), if length(_gamma_) = _g_ is longer than length(label) = _g'_, skip to the next matching child node, set _g_ to _g - g'_, _h_ to _g' + 1_, and compare character _h_ of _gamma_. If it matches, repeat, until _g < g'_. Skip to character _g_ on the edge and quit.
