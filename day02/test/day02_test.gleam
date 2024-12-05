import gleam/result
import gleam/string
import gleeunit
import gleeunit/should
import simplifile

import day02

fn input() -> String {
  simplifile.read("small-in.txt")
  |> result.lazy_unwrap(fn() { panic })
  |> string.trim
}

pub fn main() {
  gleeunit.main()
}

pub fn part1_test() {
  day02.part1(input())
  |> should.equal(2)
}

pub fn part2_test() {
  day02.part2(input())
  |> should.equal(4)
}
