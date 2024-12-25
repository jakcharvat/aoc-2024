import gleam/bool
import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import simplifile

type Coord {
  Coord(r: Int, c: Int)
}

type TopMap {
  TopMap(rows: Int, cols: Int, map: dict.Dict(Coord, Int))
}

fn get(map: TopMap, coord: Coord) -> Int {
  dict.get(map.map, coord) |> result.lazy_unwrap(fn() { panic })
}

fn parse_int(input: String) -> Int {
  input |> int.parse |> result.lazy_unwrap(fn() { panic })
}

fn parse_input(input: String) -> TopMap {
  let lines = string.trim(input) |> string.split("\n")
  let rows = list.length(lines)
  let cols =
    list.first(lines) |> result.lazy_unwrap(fn() { panic }) |> string.length

  let map =
    list.index_map(lines, fn(line, y) {
      string.split(line, "")
      |> list.index_map(fn(el, x) { #(Coord(y, x), parse_int(el)) })
    })
    |> list.flatten
    |> dict.from_list

  TopMap(rows, cols, map)
}

fn find_paths(map: TopMap, c: Coord, h: Int) -> List(Coord) {
  use <- bool.guard(!dict.has_key(map.map, c), return: [])

  let actual_h = get(map, c)
  use <- bool.guard(actual_h != h, return: [])
  use <- bool.guard(actual_h == 9, return: [c])

  [
    find_paths(map, Coord(c.r, c.c + 1), h + 1),
    find_paths(map, Coord(c.r, c.c - 1), h + 1),
    find_paths(map, Coord(c.r + 1, c.c), h + 1),
    find_paths(map, Coord(c.r - 1, c.c), h + 1),
  ]
  |> list.flatten
}

fn count_paths(map: TopMap, c: Coord, h: Int) -> Int {
  use <- bool.guard(!dict.has_key(map.map, c), return: 0)

  let actual_h = get(map, c)
  use <- bool.guard(actual_h != h, return: 0)
  use <- bool.guard(actual_h == 9, return: 1)

  [
    count_paths(map, Coord(c.r, c.c + 1), h + 1),
    count_paths(map, Coord(c.r, c.c - 1), h + 1),
    count_paths(map, Coord(c.r + 1, c.c), h + 1),
    count_paths(map, Coord(c.r - 1, c.c), h + 1),
  ]
  |> int.sum
}

pub fn part1(input: String) -> Int {
  let map = parse_input(input)
  let possible_heads =
    map.map
    |> dict.filter(fn(_, h) { h == 0 })
    |> dict.keys

  let head_scores =
    possible_heads
    |> list.map(fn(head) {
      find_paths(map, head, 0)
      |> list.unique
      |> list.length
    })

  head_scores |> int.sum
}

pub fn part2(input: String) -> Int {
  let map = parse_input(input)
  let possible_heads =
    map.map
    |> dict.filter(fn(_, h) { h == 0 })
    |> dict.keys

  let head_scores =
    possible_heads
    |> list.map(fn(head) { count_paths(map, head, 0) })

  head_scores |> int.sum
}

pub fn main() {
  let input =
    simplifile.read("input.txt")
    |> result.lazy_unwrap(fn() { panic })
    |> string.trim

  io.println("Part 1: " <> string.inspect(part1(input)))
  io.println("Part 2: " <> string.inspect(part2(input)))
}
