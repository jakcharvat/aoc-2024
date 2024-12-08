import gleam/io
import gleam/list
import gleam/result
import gleam/set
import gleam/string
import gleam/yielder
import gleam_community/maths/arithmetics
import simplifile

type Coord {
  Coord(row: Int, col: Int)
}

fn smallest_step(c: Coord) {
  let gcd = arithmetics.gcd(c.row, c.col)
  Coord(c.row / gcd, c.col / gcd)
}

fn add_coord(a: Coord, b: Coord) {
  Coord(a.row + b.row, a.col + b.col)
}

fn sub_coord(a: Coord, b: Coord) {
  Coord(a.row - b.row, a.col - b.col)
}

fn neg_coord(c: Coord) {
  Coord(-c.row, -c.col)
}

type Map {
  Map(rows: Int, cols: Int, map: List(List(Coord)))
}

fn parse_grid(input: String) -> Map {
  let lines = string.split(input, "\n")

  let height = list.length(lines)
  let width =
    string.length(list.first(lines) |> result.lazy_unwrap(fn() { panic }))

  let grid =
    lines
    |> list.index_map(fn(row, y) {
      string.split(row, "")
      |> list.index_map(fn(el, x) { #(el, Coord(y, x)) })
      |> list.filter(fn(x) { x.0 != "." })
    })
    |> list.flatten
    |> list.sort(fn(a, b) { string.compare(a.0, b.0) })
    |> list.chunk(fn(x) { x.0 })
    |> list.map(fn(chunk) { chunk |> list.map(fn(x) { x.1 }) })

  Map(height, width, grid)
}

fn calc_interference(antennas: List(Coord)) -> set.Set(Coord) {
  antennas
  |> list.combination_pairs
  |> list.map(fn(p) {
    let #(a, b) = p
    let d = sub_coord(b, a)
    set.from_list([sub_coord(a, d), add_coord(b, d)])
  })
  |> list.fold(set.new(), set.union)
}

fn in_grid(c: Coord, rows: Int, cols: Int) -> Bool {
  c.row >= 0 && c.col >= 0 && c.row < rows && c.col < cols
}

pub fn part1(input: String) -> Int {
  let Map(rows, cols, map) = parse_grid(input)

  map
  |> list.map(calc_interference)
  |> list.fold(set.new(), set.union)
  |> set.filter(in_grid(_, rows, cols))
  |> set.size
}

fn calc_infinite_interference(
  antennas: List(Coord),
  rows: Int,
  cols: Int,
) -> set.Set(Coord) {
  let step = fn(from: Coord, by: Coord) -> set.Set(Coord) {
    from
    |> yielder.iterate(add_coord(_, by))
    |> yielder.take_while(in_grid(_, rows, cols))
    |> yielder.fold(set.new(), set.insert)
  }

  antennas
  |> list.combination_pairs
  |> list.map(fn(p) {
    let #(a, b) = p
    let d = smallest_step(Coord(a.row - b.row, a.col - b.col))
    set.union(step(a, d), step(b, neg_coord(d)))
  })
  |> list.fold(set.new(), set.union)
}

pub fn part2(input: String) -> Int {
  let Map(rows, cols, map) = parse_grid(input)

  map
  |> list.map(calc_infinite_interference(_, rows, cols))
  |> list.fold(set.new(), set.union)
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
