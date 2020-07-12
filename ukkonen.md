# Esko Ukkonen's algorithm for building a suffix tree

1. If the algorithm is just beginning to add a string, start at the root. Otherwise, start from the node whose label contains the last character of extension 1 of phase _i_ (the leaf node for _S[1..i]_, referred to here as the _j1_ node). Each phase will need to return its _j1_ node for use by the next phase, phase (_i + 1_).
2. For (_j = 1, i = 1_), simply add _i_ from the root according to the [extension rules](#Extension-rules-for-adding-character-(_i-+-1_)).
3. For (_i >= 2_), start at the _j1_ node, and add (_i + 1_) to the label (this first step always follows rule 1).
4. If the current node has a suffix link, follow it, and add (_i + 1_) to the label on _s(v)_.
5. If the current node does not have a suffix link, go up one level to its parent (or the root).
6. If the parent node has a suffix link, follow it, walk _gamma_ down from _s(v)_, and add (_i + 1_) according to the rules.
7. If the last extension created a node while adding (_i + 1_), then this extension will also create one, so add the suffix link _v -> s(v)_ before moving on.
8. Repeat for _j = 1..i + 1_.
9. Start a new phase at the new _j1_ node you created during step 3.
10. When you complete phase _m_, perform a special extension, ensuring that a leaf exists for every location where `:last` would be placed. This extension is unique, because `:last` is not actually added to the tree, but the algorithm is performed as if were planning to add this unique final character.

## Extension rules for adding character (_i + 1_)

1. If _beta_ (_S[j..i]_) ends at a leaf node, add (_i + 1_) to the label.
2. If no path from _beta_ starts with (_i + 1_), either add a new child (if _beta_ ends at a node), or split the edge and add a child (if _beta_ ends in the edge).
3. If some path from _beta_ already starts with (_i + 1_) (in the edge, or as a child if _beta_ ends at a node), do nothing.
