notes:

Starting from the root is unique, because we don't care about the index, and instead go straight to matching the children for our comparison.

If we're starting from another node, we check the current index first. If the current index is nil, then we're off the end of the string and we need to match children for our comparison. In fact, it's even a bit more complicated than that, because the underlying string is longer than the label, so we need to ensure that our location of comparison is not past the last location on the label, rather than just looking at that index on the string.

In either case, either the grapheme is there or it's not.

If the grapheme is there, explicit stays the same (including if it's nil). We increment extension, but stay in the phase. Then we choose our next site of comparison by following the link, or if there is no link, by calling skip_count.

If the grapheme is not there, we create a node. Whenever we create a node, if there is an explicit we link it, then the new node becomes explicit, we increment extension, and we skip_count to find the next comparison.

We increment extension each time either way, so we need to check at the end to see if extension == phase. If it is, then we increment phase and reset extension, and we also need to set current node to the value of explicit I believe (the starting point for the next phase, since all the other extensions in that phase will have been implicit).

The key question you need to answer is how we ensure that we start with the correct value of extension, given that we might skip over some extensions if they would be done implicitly. Just resetting to 0 is not enough.

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

<!--
incorporate this into above:

# ok here is the deal - you need a last explicit node and an index
  # update the node whenever you
  # 1. create a new node
  # 2. jump to a child of last explicit to find your match (this works from root also)
  # update the index whenever you
  # 1. first add a grapheme (even if implicitly) - if the addition is implicit, it will be a show stopper anyway, so you are just incrementing the position on the label for your next comparison
# you can determine if you are first adding a grapheme by whether extension is 0
  # the corollary to that is that you have to increment extension
-->

## Basic principles

1. If you invoke rule 2 on a given extension, then you will never need to return to that node during the addition of this particular string, as our method of terminating the label at `-1` will ensure all further phases are performed implicitly on that node. Put differently, using the label `..-1` means that all explicit extensions will require the creation of a new node. You do, however, need to add a leaf for `hash, extension`, store that node in `explicit` and `current`, and start `skip_count` from there. Even if you make changes to `current`, you will need to keep that node as `explicit` until you complete `skip_count` and create the next node. Then you can fill `link` on the node and make the new node `explicit`, before repeating `skip_count`, cycling this process until all extensions in the phase are complete.

1. If you have set a newly created node to current, you need to increment `cur_index` to check the grapheme from the next phase. Then the length of the label up to `cur_index` will be the offset required for checking the grapheme match on the down-walk of `skip_count`. So just before you start the next phase (by calling `add_string/3` on `rest`), you need to increment `phase`, reset `extension`, and increment `cur_index`.

1. If you invoke rule 3, then - although you are done with the phase - you still need to increment `cur_index`, even though you are keeping `cur_node`.

## Steps for adding a string to the tree

1. First confirm that the string is present in the strings map. In practice, we do this by exposing `add_string/2`, which calls `Map.put_new/3`, and privatizing `add_string/3`, which will only be called after `%{hash => string}` is added to strings. TODO: handle collisions.

1. Check for a child of `cur_node` (initially root) whose label begins with the first grapheme of our string. We binary pattern match to get the first grapheme of the string, and call `match_child/3`, which will either return the matching node id or nil.

1. If a matching node id is returned, set `explicit` to that node id with an index of 0 (`current` will stay the same (root) for now), and increment both phase and extension (we increment phase here because phase 0 only has 1 extension, so we're done, but even if we are in a higher phase, invoking rule 3 would end the phase anyway). Return the tree and call `add_string/3` on `rest`.

1. If there is no match, create a new node with `new_node(nodes[cur_node].id)` (in this case, "root"). Add the label `{hash, phase..-1}`, which will start from 0, as this is the first phase. Add the leaf `{hash, phase}`. Set the newly created node to `explicit` with an index of 0 (index will always be zero for `explicit` when it is a newly created node).

1. Repeat the last 3 steps with the first grapheme of `rest` (phase 1), but with slight modifications:

1.
...

one thing we need to address is this:
The plan had been to add all of the leaves during the addition of :last
the issue with this is that we need to know the integer value of the leaf, in addition to the hash. although it is tempting to think that we can just add the leaf at the time of node creation, this creates complexity on a future string addition. but it may still work, as if we split the label, the leaf value for the terminal node will still be valid, although the label will be shorter. however the issue is when to add the leaf—once a leaf always a leaf—so i think we add right at node creation.

so the rule should be - if you create a node, add the leaf for that hash, based on the value of `extension`. if you do create a node, either by splitting the label or adding a child, then by adding the leaf and the label (to -1), you are essentially done with the entire addition of the string for that extension, and you only need to use skip count once, adding the string all the way to the end each time, and then creating the suffix link. for skip count, what matters is how far along the label you are, because that's how far down you need to go after following the parent's suffix link. that value will come from current?... because you are adding the string by creating a node, you won't have to call with :last, although probably the best way to handle it is to call with :last and have a case that does nothing if you created the node (how?). if you reach :last without creating a , then check for the leaf on each node, and add it if not present. when you start :last, by definition all of the suffix links should already be in place, so you simply need to follow them


1. Since this is a new node, it (by definition) will not have a suffix link yet. That means you must leave it as `explicit` until you add the new node for the next extension.

1. In addition, since this is the first phase of our string addition, we know that it will consist of adding at most 1 node, so we can increment phase, reset extension, set `current` to root, and go on to phase 2.

1. Call `add_string/3` on the updated tree and `rest`, which will again match on the root case and call `match_child/3` on root's children.




1. If a matching node id is returned, ...

1. Use `skip_count/1` to add the next extension, which will require a new node (since the last one did). `{hash, phase}` will tell us the grapheme on the current node's label. Since we just added the label, we know it has length 1, even if we added it from `phase..-1` preemptively.

1. So in this case, we follow the suffix link from the parent, which will be root.

  if there is a match, make that node current and explicit, increment the index, increment the extension, and return the tree

  if there is no match, create a node, make its parent "root", add the grapheme to the label, add the node to root's children, set the new node to current and explicit, replace root and add the new node in nodes, add nodes and the mods to explicit/current to the tree, increment extension and return the tree

  move to checking the next grapheme

  start at current, check the current index on the label and compare to grapheme
  if there is a match, increment the index for current, explicit, and the extension. set cur_node but not exp_node. return the tree

  if there is no match
