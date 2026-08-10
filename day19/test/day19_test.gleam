import gleam/result
import gleam/string
import gleeunit
import gleeunit/should
import simplifile

import day19

fn input() -> String {
  simplifile.read("small-in.txt")
  |> result.lazy_unwrap(fn() { panic })
  |> string.trim
}

pub fn main() {
  gleeunit.main()
}

pub fn part1_test() {
  day19.part1(input())
  |> should.equal(6)
}

pub fn part2_test() {
  day19.part2(input())
  |> should.equal(16)
}
