import gleam/int
import gleam/io
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/regexp
import gleam/result
import gleam/string
import simplifile

fn force_unwrap(o) {
  option.lazy_unwrap(o, fn() { panic })
}

fn eval_mul(mul: regexp.Match) -> Int {
  let assert [a, b] =
    mul.submatches
    |> list.map(fn(m) {
      force_unwrap(m) |> int.parse |> option.from_result |> force_unwrap
    })

  a * b
}

fn calc_muls(input: String) {
  let assert Ok(rex) = regexp.from_string("mul\\((\\d+),(\\d+)\\)")
  let matches = regexp.scan(rex, input)

  matches
  |> list.map(eval_mul)
  |> int.sum
}

pub fn part1(input: String) -> Int {
  calc_muls(input)
}

pub fn first(l: List(a)) -> Option(a) {
  case l {
    [head, ..] -> Some(head)
    [] -> None
  }
}

fn take(haystack: String, until needle: String) -> String {
  case string.split(haystack, on: needle) {
    [head, ..] -> head
    [] -> ""
  }
}

fn apply_do_dont(input: String) -> List(String) {
  input
  |> string.split("do()")
  |> list.map(take(_, until: "don't()"))
}

pub fn part2(input: String) -> Int {
  apply_do_dont(input)
  |> list.map(calc_muls)
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
