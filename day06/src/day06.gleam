import gleam/bool
import gleam/io
import gleam/list
import gleam/result
import gleam/set
import gleam/string
import simplifile

fn force_unwrap(r: Result(a, e)) -> a {
  result.lazy_unwrap(r, fn() { panic })
}

type Coord {
  Coord(row: Int, col: Int)
}

type Map {
  Map(rows: Int, cols: Int, map: set.Set(Coord))
}

type Dir {
  Up
  Right
  Down
  Left
}

fn dir_from_string(str: String) {
  case str {
    "^" -> Ok(Up)
    ">" -> Ok(Right)
    "v" -> Ok(Down)
    "<" -> Ok(Left)
    _ -> Error(Nil)
  }
}

fn right(from dir: Dir) -> Dir {
  case dir {
    Up -> Right
    Right -> Down
    Down -> Left
    Left -> Up
  }
}

fn step(dir: Dir) -> Coord {
  case dir {
    Up -> Coord(-1, 0)
    Right -> Coord(0, 1)
    Down -> Coord(1, 0)
    Left -> Coord(0, -1)
  }
}

fn add_coord(a: Coord, b: Coord) -> Coord {
  Coord(a.row + b.row, a.col + b.col)
}

type Guard {
  Guard(pos: Coord, dir: Dir)
}

fn result_when(condition: Bool, give good_val: a) -> Result(a, Nil) {
  case condition {
    True -> Ok(good_val)
    False -> Error(Nil)
  }
}

fn parse_input(input: String) -> #(Map, Guard) {
  let lines =
    input
    |> string.split("\n")

  let els =
    lines
    |> list.index_map(fn(row, y) {
      list.index_map(string.split(row, ""), fn(el, x) { #(el, Coord(y, x)) })
    })
    |> list.flatten

  let map =
    els
    |> list.filter_map(fn(x) { result_when(x.0 == "#", give: x.1) })
    |> set.from_list

  let height = list.length(lines)
  let width = string.length(list.first(lines) |> force_unwrap)
  let map = Map(height, width, map)

  let assert [guard] =
    els
    |> list.filter_map(fn(x) {
      dir_from_string(x.0) |> result.map(fn(dir) { Guard(x.1, dir) })
    })

  #(map, guard)
}

fn map_contains(map: Map, coord: Coord) -> Bool {
  coord.row >= 0
  && coord.col >= 0
  && coord.row < map.rows
  && coord.col < map.cols
}

fn guard_step(map: Map, guard: Guard) -> Guard {
  let step = add_coord(guard.pos, step(guard.dir))
  use <- bool.guard(
    when: !set.contains(map.map, step),
    return: Guard(step, guard.dir),
  )

  guard_step(map, Guard(guard.pos, right(guard.dir)))
}

fn get_visited(
  map: Map,
  guard: Guard,
  visited: set.Set(Coord),
) -> set.Set(Coord) {
  use <- bool.guard(when: !map_contains(map, guard.pos), return: visited)
  let visited = set.insert(visited, guard.pos)

  get_visited(map, guard_step(map, guard), visited)
}

fn check_loop(map: Map, guard: Guard, visited: set.Set(Guard)) -> Bool {
  use <- bool.guard(when: !map_contains(map, guard.pos), return: False)
  use <- bool.guard(when: set.contains(visited, guard), return: True)
  let visited = set.insert(visited, guard)

  check_loop(map, guard_step(map, guard), visited)
}

pub fn part1(input: String) -> Int {
  let #(map, guard) = parse_input(input)
  get_visited(map, guard, set.new()) |> set.size
}

pub fn part2(input: String) -> Int {
  let #(map, guard) = parse_input(input)
  let walk = get_visited(map, guard, set.new())

  walk
  |> set.filter(fn(coord) { coord != guard.pos })
  |> set.filter(fn(coord) {
    check_loop(Map(..map, map: set.insert(map.map, coord)), guard, set.new())
  })
  |> set.size
}

pub fn main() {
  let input =
    simplifile.read("input.txt")
    |> result.lazy_unwrap(fn() { panic })
    |> string.trim

  io.println("Part 1: " <> string.inspect(part1(input)))
  io.println("Part 2: " <> string.inspect(part2(input)))
}
