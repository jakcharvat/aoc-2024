import gleam/io
import gleam/string
import simplifile

pub fn part1(input: String) -> Int {
  todo
}

pub fn part2(input: String) -> Int {
  todo
}

pub fn main() {
  let input =
    simplifile.read("input.txt")
    |> result.lazy_unwrap(fn() { panic })
    |> string.trim

  io.println("Part 1: " <> string.inspect(part1(input)))
  io.println("Part 2: " <> string.inspect(part2(input)))
}
