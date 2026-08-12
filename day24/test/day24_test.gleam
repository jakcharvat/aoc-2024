import gleam/result
import gleam/string
import gleeunit
import gleeunit/should
import simplifile

import day24

fn input(filename: String) -> String {
  simplifile.read(filename)
  |> result.lazy_unwrap(fn() { panic })
  |> string.trim
}

pub fn main() {
  gleeunit.main()
}

pub fn part1_test() {
  day24.part1(input("tiny-in.txt"))
  |> should.equal(4)

  day24.part1(input("small-in.txt"))
  |> should.equal(2024)
}
