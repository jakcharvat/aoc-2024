import gleam/int
import gleam/list
import gleam/result
import gleam/string
import gleeunit
import gleeunit/should
import simplifile

import day20

fn input() -> String {
  simplifile.read("small-in.txt")
  |> result.lazy_unwrap(fn() { panic })
  |> string.trim
}

pub fn main() {
  gleeunit.main()
}

pub fn part1_test() {
  day20.tally_cheats(input())
  |> list.sort(fn(a, b) { int.compare(a.time_saved, b.time_saved) })
  |> should.equal([
    day20.CheatTally(time_saved: 2, count: 14),
    day20.CheatTally(time_saved: 4, count: 14),
    day20.CheatTally(time_saved: 6, count: 2),
    day20.CheatTally(time_saved: 8, count: 4),
    day20.CheatTally(time_saved: 10, count: 2),
    day20.CheatTally(time_saved: 12, count: 3),
    day20.CheatTally(time_saved: 20, count: 1),
    day20.CheatTally(time_saved: 36, count: 1),
    day20.CheatTally(time_saved: 38, count: 1),
    day20.CheatTally(time_saved: 40, count: 1),
    day20.CheatTally(time_saved: 64, count: 1),
  ])
}

pub fn part2_test() {
  day20.tally_long_cheats(input(), 50)
  |> list.sort(fn(a, b) { int.compare(a.time_saved, b.time_saved) })
  |> should.equal([
    day20.CheatTally(time_saved: 50, count: 32),
    day20.CheatTally(time_saved: 52, count: 31),
    day20.CheatTally(time_saved: 54, count: 29),
    day20.CheatTally(time_saved: 56, count: 39),
    day20.CheatTally(time_saved: 58, count: 25),
    day20.CheatTally(time_saved: 60, count: 23),
    day20.CheatTally(time_saved: 62, count: 20),
    day20.CheatTally(time_saved: 64, count: 19),
    day20.CheatTally(time_saved: 66, count: 12),
    day20.CheatTally(time_saved: 68, count: 14),
    day20.CheatTally(time_saved: 70, count: 12),
    day20.CheatTally(time_saved: 72, count: 22),
    day20.CheatTally(time_saved: 74, count: 4),
    day20.CheatTally(time_saved: 76, count: 3),
  ])
}
