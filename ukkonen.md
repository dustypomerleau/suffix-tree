# Esko Ukkonen's algorithm for building a suffix tree

**NOTE:** This document is meant as a convenient reference for those working on the repository. By itself, it is not sufficient to teach Ukkonen's algorithm. If you are interested in learning Ukkonen's approach to suffix tree construction, I would strongly recommend Dan Gusfeld's _Algorithms on Strings, Trees, and Sequences_.

In our slightly modified approach to Ukkonen's algorithm, leaves are represented virtually, as a list on their parent node (rather than creating a `Node` struct purely to hold the identity of the leaf). When we refer to a _leaf node_, we mean a node without children. This node will contain a reference to at least one virtual leaf (held in the `leaves` field in the form `{hash, j}`) but it may contain an arbitrary number of leaves. Additions at these true leaf nodes invoke rule 1. Leaves may be represented on intermediate nodes as well, but when _&gamma;_ ends at an intermediate node, we invoke rule 2, and create an appropriate new leaf, in addition to adding any new nodes necessary for adding _i + 1_.

1. If the algorithm is just beginning to add a string, start at the root. Otherwise, start from the _j - 1_ leaf node (the last node requiring an _explicit_ extension). By strict Ukkonen, whenever we add a new leaf, its label should be set to _p..e_ and _e_ should be incremented for each extension. However, if we pre-calculate _m_, it could simply be set to _0..m_ once at the time of creation, eliminating the need to hold and increment variable _e_. But if we are going to take this approach, it's not necessary to calculate _m_ at all, given that Elixir allows the range `p..-1`, so in our case this will be the preferred approach. Some caution is needed, as we will be using 0-based indices, and both `length/1`, and the documentation of Ukkonen's method are 1-based.
1. For _j = 0, i = 0_, simply add `String.at(string, 0)` from the root according to the [extension rules](#Extension-rules-for-adding-character-(_i-+-1_)). Adding the character includes adding the node (if not already present), referencing the node as a child of the root, adding the label `{hash, 0..-1}` (unless a previous string has added it), the leaf {`hash, 0`}, and the parent (in this case, `"root"`, but for other parents the appropriate `id`).
1. For _i >= 1_, start at the _j - 1_ leaf node, and add _i + 1_ to the label (this first step always follows rule 1, and does not require any up or down walking).
1. If the current node has a suffix link, follow it, and add _i + 1_ to the label on _s(v)_.
1. If the current node does not have a suffix link, go up one level to its parent (or the root).
1. Follow the parent's suffix link (or start from the root if the parent is the root), walk _&gamma;_ down from _s(v)_ using [the skip count algorithm](#Skip-count-algorithm), and add _i + 1_ according to the rules.
1. If extension _j_ created a node while adding _i + 1_, then extension _j + 1_ will also create one, so add the suffix link _v -> s(v)_ before moving on.
1. If rule 2 is invoked, you will create a leaf. The leaf will always be `{hash, j}`, but the node labels will need to be adjusted. When we split an edge, we will need to set both _p_ and _q_ on the newly added upstream node label, and adjust _p_ only on the leaf node label (since, by definition, the leaf node's label ends at _m_)
1. Repeat this pattern of going up and across the suffix link for _j = (j - 1..i + 1)_ (or until you invoke rule 3).
1. If rule 3 is invoked, end the phase.
1. Take note of _j_ when you hit rule 3. _j - 1_ is the leaf node for the last _explicit_ extension you did. If a particular phase requires no explicit extensions, then the _j - 1_ node remains unchanged from the last phase.
1. Start the next phase from the leaf node of extension _j - 1_.
1. When you complete phase _m_, perform a special extension, ensuring that a leaf exists for every location where `:last` would be placed. This extension is unique, because `:last` is not actually added to the tree, but the algorithm is performed as if were planning to add this unique final character. Invoking rule 2 for `:last` will create nodes to hold the final leaves if they aren't already present, and result in adding `hash` for the current string to `leaves` with the appropriate value for _j_. Using the method we've outlined should mean that situations in which we would invoke rule 1 will already be handled (as we are labeling those leaves at the time of leaf node creation).

## Extension rules for adding character (_i + 1_)

1. If _&beta;_, (_S[j..i]_), ends at a leaf node, add _i + 1_ to the label.
1. If no path from _&beta;_ starts with _i + 1_, either add a new child (if _&beta;_ ends at a node), or split the edge and add a node (if _&beta;_ ends in the edge). Add the appropriate leaf to the new node.
1. If some path from _&beta;_ already starts with _i + 1_ (in the edge, or as a child if _&beta;_ ends at a node), do nothing.

## Skip count algorithm

1. When walking down from s(v), if length(_&gamma;_) = _g_ is longer than length(label) = _g'_, skip to the next matching child node, set _g_ to (_g - g'_), _h_ to (_g' + 1_), and compare character _h_ of _&gamma;_. If it matches, repeat, until _g < g'_. Skip to character _g_ on the edge and quit.
