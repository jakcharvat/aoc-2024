import gleam/result
import gleam/string
import gleeunit
import gleeunit/should
import simplifile

import day01

fn input() -> String {
  simplifile.read("small-in.txt")
  |> result.lazy_unwrap(fn() { panic })
  |> string.trim
}

pub fn main() {
  gleeunit.main()
}

pub fn part1_test() {
  day01.part1(input())
  |> should.equal(11)
}

pub fn part2_test() {
  day01.part2(input())
  |> should.equal(31)
}
