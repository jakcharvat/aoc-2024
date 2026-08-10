import gleam/result
import gleam/string
import gleeunit
import gleeunit/should
import simplifile

import day18

fn input() -> String {
  simplifile.read("small-in.txt")
  |> result.lazy_unwrap(fn() { panic })
  |> string.trim
}

pub fn main() {
  gleeunit.main()
}

pub fn part1_test() {
  day18.part1(input(), 6, 12)
  |> should.equal(22)
}

pub fn part2_test() {
  day18.part2(input(), 6)
  |> should.equal("6,1")
}
