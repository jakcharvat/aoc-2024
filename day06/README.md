# Day 06

First part was ok. Simulate the walk of the guard and count the number of squares they visit.
No fancy tricks, just the input parsing was painful as usual.

The second part could definitely be implemented better. Currently, I find the guard's path from the
first part, and attempt to place a block at every point of the path. For every such block I then
simulate the guard's path again to see if a cycle forms.

This could perhaps be optimised by finding all paths that lead to starting position, then
simulating a single walk of the guard and counting places where we overlap the already walked path
or the tree that leads to the starting position.

If n is the side length of the map, 130 for my input, my current implementation runs in
(walk_length * n^2) time, which in the worst case is n^4. It takes around 5s on my machine. The
solution with first finding the states which lead to the initial position should be a single maze
search and a single simulation, so should run in n^2 time.
