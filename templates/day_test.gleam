import gleam/result
import gleam/string
import gleeunit
import gleeunit/should
import simplifile

import day__DAY_NUM__

fn input() -> String {
  simplifile.read("small-in.txt")
  |> result.lazy_unwrap(fn() { panic })
  |> string.trim
}

pub fn main() {
  gleeunit.main()
}

pub fn part1_test() {
  day__DAY_NUM__.part1(input())
  |> should.equal(todo)
}

pub fn part2_test() {
  day__DAY_NUM__.part2(input())
  |> should.equal(todo)
}
