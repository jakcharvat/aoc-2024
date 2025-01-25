import gleam/bool
import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import simplifile

import part2

fn num_digits(x: Int) -> Int {
  let log = fn(x: Float) {
    float.logarithm(x) |> result.lazy_unwrap(fn() { panic })
  }
  let log10 = fn(x: Int) { log(int.to_float(x)) /. log(10.0) }
  { log10(x) |> float.truncate } + 1
}

fn split_digits(x: Int) -> Result(#(Int, Int), Nil) {
  let digits = num_digits(x)
  use <- bool.guard(digits % 2 == 1, return: Error(Nil))

  let d =
    int.power(10, int.to_float(digits / 2))
    |> result.lazy_unwrap(fn() { panic })
    |> float.truncate

  Ok(#(x / d, x % d))
}

fn simulate_stone(stone: Int, iters: Int) -> Int {
  use <- bool.guard(iters == 0, return: 1)

  case stone {
    0 -> simulate_stone(1, iters - 1)
    x -> {
      case split_digits(x) {
        Ok(#(a, b)) ->
          simulate_stone(a, iters - 1) + simulate_stone(b, iters - 1)

        Error(_) -> simulate_stone(x * 2024, iters - 1)
      }
    }
  }
}

fn parse_int(x: String) -> Int {
  x |> int.parse |> result.lazy_unwrap(fn() { panic })
}

fn parse_input(input: String) -> List(Int) {
  input |> string.split(" ") |> list.map(parse_int)
}

pub fn part1(input: String) -> Int {
  input
  |> parse_input
  |> list.map(simulate_stone(_, 25))
  |> int.sum
}

pub fn part2(input: String) -> Int {
  part2.part2(parse_input(input))
}

pub fn main() {
  let input =
    simplifile.read("input.txt")
    |> result.lazy_unwrap(fn() { panic })
    |> string.trim

  io.println("Part 1: " <> string.inspect(part1(input)))
  io.println("Part 2: " <> string.inspect(part2(input)))
}
