import gleam/bool
import gleam/deque
import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/set
import gleam/string
import simplifile

type Coord {
  Coord(x: Int, y: Int)
}

fn coord_add(a: Coord, b: Coord) -> Coord {
  Coord(x: a.x + b.x, y: a.y + b.y)
}

fn steps() -> List(Coord) {
  [
    Coord(x: 1, y: 0),
    Coord(x: 0, y: 1),
    Coord(x: -1, y: 0),
    Coord(x: 0, y: -1),
  ]
}

type Grid {
  Grid(size: Int, grid: set.Set(Coord))
}

fn parse_int(s: String) -> Int {
  case int.parse(s) {
    Ok(n) -> n
    Error(_) -> panic as { "invalid int: " <> s }
  }
}

fn parse_coord(line: String) -> Coord {
  let assert [x, y] = string.split(line, ",") |> list.map(parse_int)
  Coord(x:, y:)
}

fn parse(input: String) -> List(Coord) {
  string.trim(input)
  |> string.split("\n")
  |> list.map(parse_coord)
}

fn prep_grid(size: Int) -> Grid {
  let start_coords =
    set.from_list([
      Coord(x: -1, y: -1),
      Coord(x: -1, y: size + 1),
      Coord(x: size + 1, y: -1),
      Coord(x: size + 1, y: size + 1),
    ])

  int.range(0, size + 1, start_coords, fn(set, i) {
    set.union(
      set,
      set.from_list([
        Coord(x: i, y: -1),
        Coord(x: i, y: size + 1),
        Coord(x: -1, y: i),
        Coord(x: size + 1, y: i),
      ]),
    )
  })
  |> Grid(size:, grid: _)
}

fn drop_all(grid: Grid, drops: List(Coord)) -> Grid {
  Grid(..grid, grid: set.union(grid.grid, set.from_list(drops)))
}

fn show_grid(grid: Grid) -> String {
  let Grid(size:, grid:) = grid

  int.range(0, size + 1, "", fn(s, y) {
    s
    <> int.range(0, size + 1, "", fn(line, x) {
      line
      <> case set.contains(grid, Coord(x:, y:)) {
        True -> "#"
        False -> "."
      }
    })
    <> "\n"
  })
}

type Qel {
  Qel(coord: Coord, depth: Int)
}

fn walk_rec(
  grid: Grid,
  q: deque.Deque(Qel),
  seen: set.Set(Coord),
) -> Result(Int, Nil) {
  case deque.pop_front(q) {
    Ok(#(Qel(coord:, depth:), q)) -> {
      case coord == Coord(grid.size, grid.size) {
        True -> Ok(depth)
        False -> {
          let #(q, seen) =
            list.fold(steps(), #(q, seen), fn(acc, step) {
              let neigh = coord_add(coord, step)

              use <- bool.guard(
                when: set.contains(grid.grid, neigh)
                  || set.contains(seen, neigh),
                return: acc,
              )

              let #(q, seen) = acc
              #(
                deque.push_back(q, Qel(coord: neigh, depth: depth + 1)),
                set.insert(seen, neigh),
              )
            })

          walk_rec(grid, q, seen)
        }
      }
    }

    Error(_) -> Error(Nil)
  }
}

fn walk(grid: Grid) -> Int {
  let start = Coord(0, 0)
  let q = deque.from_list([Qel(coord: start, depth: 0)])
  let seen = set.from_list([start])

  walk_rec(grid, q, seen)
  |> result.lazy_unwrap(fn() { panic as "No path found!" })
}

pub fn part1(input: String, size: Int, initial_drops: Int) -> Int {
  let drops = parse(input)

  let grid = prep_grid(size)
  io.println(show_grid(grid))

  let dropped_grid = drop_all(grid, drops |> list.take(initial_drops))
  io.println(show_grid(dropped_grid))

  walk(dropped_grid)
}

type UF {
  UF(roots: dict.Dict(Coord, Coord))
}

fn uf_new() -> UF {
  UF(roots: dict.new())
}

fn uf_insert(uf: UF, coord: Coord) -> UF {
  assert !dict.has_key(uf.roots, coord)
    as "Attempting to insert already existing coord into UF"

  UF(dict.insert(uf.roots, coord, coord))
}

fn uf_find(uf: UF, coord: Coord) -> #(Result(Coord, Nil), UF) {
  case dict.get(uf.roots, coord) {
    Error(_) -> #(Error(Nil), uf)
    Ok(root) ->
      case coord == root {
        True -> #(Ok(coord), uf)
        False -> {
          // If I already have a root, it should have a root too
          let assert #(Ok(root), uf) = uf_find(uf, root)
          let uf = UF(dict.insert(uf.roots, coord, root))
          #(Ok(root), uf)
        }
      }
  }
}

fn uf_union(uf: UF, coord: Coord, root: Coord) -> UF {
  use <- bool.guard(
    when: !dict.has_key(uf.roots, coord) || !dict.has_key(uf.roots, root),
    return: uf,
  )

  let assert #(Ok(coord_root), uf) = uf_find(uf, coord)
  let assert #(Ok(root), uf) = uf_find(uf, root)

  UF(dict.insert(uf.roots, coord_root, root))
}

fn uf_clean_block(uf: UF, coord: Coord) -> UF {
  uf
  |> uf_insert(coord)
  |> list.fold(steps(), _, fn(uf, step) {
    uf_union(uf, coord, coord_add(coord, step))
  })
}

fn grid_clean_block(grid: Grid, coord: Coord) -> Grid {
  Grid(size: grid.size, grid: set.delete(grid.grid, coord))
}

fn idx_to_char(i: Int) -> String {
  let indices = string.split("abcdefghijklmnopqrstuvwxyz", "")
  let num_indices = list.length(indices)

  case i {
    i if i < num_indices -> {
      let assert [val, ..] = list.drop(indices, i)
      val
    }
    _ -> "+"
  }
}

fn show_uf_grid(uf: UF, grid: Grid) -> String {
  let uf =
    list.fold(dict.keys(uf.roots), uf, fn(uf, key) {
      let assert #(Ok(_), uf) = uf_find(uf, key)
      uf
    })

  let root_indices =
    uf.roots
    |> dict.to_list
    |> list.fold(dict.new(), fn(indices, entry) {
      let #(_, root) = entry
      case dict.has_key(indices, root) {
        True -> indices
        False -> dict.insert(indices, root, dict.size(indices))
      }
    })

  let Grid(size:, grid:) = grid

  int.range(0, size + 1, "", fn(s, y) {
    s
    <> int.range(0, size + 1, "", fn(line, x) {
      let coord = Coord(x:, y:)
      line
      <> case set.contains(grid, coord) {
        True -> "#"
        False -> {
          let assert #(Ok(root), _) = uf_find(uf, coord)
          let assert Ok(idx) = dict.get(root_indices, root)
          idx_to_char(idx)
        }
      }
    })
    <> "\n"
  })
}

fn first_cutoff_rec(
  grid: Grid,
  uf: UF,
  remaining_drops: List(Coord),
) -> Result(Coord, Nil) {
  case remaining_drops {
    [] -> Error(Nil)
    [drop, ..remaining_drops] -> {
      let uf = uf_clean_block(uf, drop)
      let grid = grid_clean_block(grid, drop)

      let #(start, uf) = uf_find(uf, Coord(0, 0))
      let #(end, uf) = uf_find(uf, Coord(grid.size, grid.size))

      case start, end {
        Ok(start), Ok(end) if start == end -> {
          show_uf_grid(uf, grid) |> io.println
          Ok(drop)
        }
        _, _ -> {
          first_cutoff_rec(grid, uf, remaining_drops)
        }
      }
    }
  }
}

fn first_cutoff(grid: Grid, drops: List(Coord)) -> Coord {
  let full_grid =
    int.range(0, grid.size + 1, set.new(), fn(g, y) {
      int.range(0, grid.size + 1, g, fn(g, x) { set.insert(g, Coord(x:, y:)) })
    })

  let free_spots = set.difference(full_grid, set.from_list(drops))
  let end_grid = drop_all(grid, drops)

  let uf =
    set.to_list(free_spots)
    |> list.fold(uf_new(), uf_clean_block)

  show_uf_grid(uf, end_grid) |> io.println
  assert dict.keys(uf.roots) |> set.from_list == free_spots

  first_cutoff_rec(end_grid, uf, list.reverse(drops))
  |> result.lazy_unwrap(fn() { panic as "Start and end never connect!" })
}

pub fn part2(input: String, size: Int) -> String {
  let drops = parse(input)
  let grid = prep_grid(size)

  let Coord(x, y) = first_cutoff(grid, drops)
  int.to_string(x) <> "," <> int.to_string(y)
}

pub fn main() {
  let input =
    simplifile.read("input.txt")
    |> result.lazy_unwrap(fn() { panic })
    |> string.trim

  io.println("Part 1: " <> string.inspect(part1(input, 70, 1024)))
  io.println("Part 2: " <> string.inspect(part2(input, 70)))
}
