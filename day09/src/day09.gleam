import gleam/io
import gleam/result
import gleam/string
import simplifile

import part1
import part2

pub fn part1(input: String) {
  part1.part1(input)
}

pub fn part2(input: String) -> Int {
  part2.part2(input)
}

pub fn main() {
  let input =
    simplifile.read("input.txt")
    |> result.lazy_unwrap(fn() { panic })
    |> string.trim

  io.println("Part 1: " <> string.inspect(part1(input)))
  io.println("Part 2: " <> string.inspect(part2(input)))
}
