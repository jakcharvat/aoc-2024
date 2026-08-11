import gleam/result
import gleam/string
import gleeunit
import gleeunit/should
import simplifile

import day22

fn input(infile: String) -> String {
  simplifile.read(infile)
  |> result.lazy_unwrap(fn() { panic })
  |> string.trim
}

pub fn main() {
  gleeunit.main()
}

pub fn part1_test() {
  day22.part1(input("small-in.txt"))
  |> should.equal(37_327_623)
}

pub fn part2_test() {
  day22.part2(input("small-in2.txt"))
  |> should.equal(23)
}
