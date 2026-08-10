import gleam/result
import gleam/string
import gleeunit
import gleeunit/should
import simplifile

import day17

fn input(filename: String) -> String {
  simplifile.read(filename)
  |> result.lazy_unwrap(fn() { panic })
  |> string.trim
}

pub fn main() {
  gleeunit.main()
}

pub fn part1_test() {
  day17.part1(input("small-in.txt"))
  |> should.equal("4,6,3,5,6,3,5,2,1,0")
}

pub fn part2_test() {
  day17.part2(input("small-in2.txt"))
  |> should.equal(117_440)
}
