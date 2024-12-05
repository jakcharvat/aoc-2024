import gleam/int
import gleam/io
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import simplifile

fn parse_report(line: String) -> List(Int) {
  line
  |> string.split(" ")
  |> list.map(fn(x) { int.parse(x) |> result.lazy_unwrap(fn() { panic }) })
}

fn sgn(x: Int) -> Int {
  case x {
    0 -> 0
    x -> x / int.absolute_value(x)
  }
}

fn is_good(report: List(Int)) -> Bool {
  let deltas =
    report
    |> list.window_by_2
    |> list.map(fn(x) { x.0 - x.1 })

  let diff_good =
    deltas
    |> list.all(fn(x) {
      int.absolute_value(x) >= 1 && int.absolute_value(x) <= 3
    })

  let sign_good =
    deltas
    |> list.window_by_2
    |> list.all(fn(x) { sgn(x.0) == sgn(x.1) })

  diff_good && sign_good
}

pub fn part1(input: String) -> Int {
  input
  |> string.split("\n")
  |> list.map(parse_report)
  |> list.filter(is_good)
  |> list.length
}

fn drop_el(l: List(Int), i: Int) -> List(Int) {
  case l, i {
    [_, ..tail], 0 -> tail
    [head, ..tail], i -> [head, ..drop_el(tail, i - 1)]
    [], _ -> []
  }
}

fn is_good_with_removal(report: List(Int)) -> Bool {
  list.range(0, list.length(report))
  |> list.map(drop_el(report, _))
  |> list.any(is_good)
}

pub fn part2(input: String) -> Int {
  input
  |> string.split("\n")
  |> list.map(parse_report)
  |> list.filter(is_good_with_removal)
  |> list.length
}

pub fn main() {
  let input =
    simplifile.read("input.txt")
    |> result.lazy_unwrap(fn() { panic })
    |> string.trim

  io.println("Part 1: " <> string.inspect(part1(input)))
  io.println("Part 2: " <> string.inspect(part2(input)))
}
