# Godot Maze Door Placement Logic

## Understanding `maze[x][z]`

Your maze is a 2D grid:

- `x` = left/right
- `z` = up/down

### Grid Example:

```text
(0,0) → top-left

Position Reference
      z-1
       ↑
x-1 ← [X] → x+1
       ↓
      z+1

[X] = current maze cell

Neighbor Positions
Current:
maze[x][z]
Left:
maze[x - 1][z]
Right:
maze[x + 1][z]
Top:
maze[x][z - 1]
Bottom:
maze[x][z + 1]
Example

If current wall is:

maze[10][15]

Then:

Left → maze[9][15]
Right → maze[11][15]
Top → maze[10][14]
Bottom → maze[10][16]

Vertical Door Logic

A vertical wall looks like:

  Wall
Empty X Empty
  Wall
Meaning:
Top = wall
Bottom = wall
Left = empty
Right = empty
Code:
if top == 1 and bottom == 1 and left == 0 and right == 0:
Door Direction:
|
|
Horizontal Door Logic

A horizontal wall looks like:

Empty
Wall X Wall
Empty
Meaning:
Left = wall
Right = wall
Top = empty
Bottom = empty
Code:
elif left == 1 and right == 1 and top == 0 and bottom == 0:
Door Direction:
---