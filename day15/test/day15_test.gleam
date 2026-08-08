import gleam/result
import gleam/string
import gleeunit
import gleeunit/should
import simplifile

import day15

fn small_input() -> String {
  simplifile.read("small-in.txt")
  |> result.lazy_unwrap(fn() { panic })
  |> string.trim
}

fn tiny_input() -> String {
  simplifile.read("tiny-in.txt")
  |> result.lazy_unwrap(fn() { panic })
  |> string.trim
}

pub fn main() {
  gleeunit.main()
}

pub fn part1_test() {
  day15.part1(tiny_input())
  |> should.equal(2028)

  day15.part1(small_input())
  |> should.equal(10_092)
}

pub fn part2_test() {
  day15.part2(small_input())
  |> should.equal(9021)
}
