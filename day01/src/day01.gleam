import gleam/dict
import gleam/function
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import simplifile

fn parse_int(s: String) -> Int {
  let assert Ok(x) = int.parse(s)
  x
}

fn diff(l: List(Int)) -> Int {
  let assert [a, b] = l
  int.absolute_value(a - b)
}

fn get_lists(input: String) -> List(List(Int)) {
  input
  |> string.split(on: "\n")
  |> list.map(fn(x) { x |> string.split("   ") })
  |> list.transpose
  |> list.map(list.map(_, parse_int))
}

pub fn part1(input: String) -> Int {
  get_lists(input)
  |> list.map(list.sort(_, by: int.compare))
  |> list.transpose
  |> list.map(diff)
  |> int.sum
}

pub fn part2(input: String) -> Int {
  let assert [l, r] = get_lists(input)
  let counts =
    r
    |> list.group(function.identity)
    |> dict.map_values(fn(_, v) { list.length(v) })

  l
  |> list.map(fn(x) { x * { dict.get(counts, x) |> result.unwrap(0) } })
  |> int.sum
}

pub fn main() {
  let input =
    simplifile.read("input.txt")
    |> result.lazy_unwrap(fn() { panic })
    |> string.trim

  io.println("Part 1: " <> string.inspect(part1(input)))
  io.println("Part 2: " <> string.inspect(part2(input)))
}
