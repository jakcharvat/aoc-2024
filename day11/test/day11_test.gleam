import gleam/result
import gleam/string
import gleeunit
import gleeunit/should
import simplifile

import day11

fn input() -> String {
  simplifile.read("small-in.txt")
  |> result.lazy_unwrap(fn() { panic })
  |> string.trim
}

pub fn main() {
  gleeunit.main()
}

pub fn part1_test() {
  day11.part1(input())
  |> should.equal(55_312)
}
