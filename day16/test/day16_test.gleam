import gleam/result
import gleam/string
import gleeunit
import gleeunit/should
import simplifile

import day16

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
  day16.part1(tiny_input())
  |> should.equal(7036)

  day16.part1(small_input())
  |> should.equal(11_048)
}

pub fn part2_test() {
  day16.part2(tiny_input())
  |> should.equal(45)

  day16.part2(small_input())
  |> should.equal(64)
}
