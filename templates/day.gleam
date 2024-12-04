import gleam/io
import gleam/string
import simplifile

fn input() -> String {
  let assert Ok(input) = simplifile.read("input.txt")
  input |> string.trim
}

pub fn part1(input: String) -> Int {
  todo
}

pub fn part2(input: String) -> Int {
  todo
}

pub fn main() {
  let input = input()
  io.println("Part 1: " <> string.inspect(part1(input)))
  io.println("Part 2: " <> string.inspect(part2(input)))
}
