import gleam/result
import gleam/string
import gleeunit
import gleeunit/should
import simplifile

import day03

fn input(filename: String) -> String {
  simplifile.read(filename)
  |> result.lazy_unwrap(fn() { panic })
  |> string.trim
}

pub fn main() {
  gleeunit.main()
}

pub fn part1_test() {
  day03.part1(input("small-in1.txt"))
  |> should.equal(161)
}

pub fn part2_test() {
  day03.part2(input("small-in2.txt"))
  |> should.equal(48)
}
