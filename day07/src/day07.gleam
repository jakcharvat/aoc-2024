import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import simplifile

fn parse_int(s: String) -> Int {
  s |> int.parse |> result.lazy_unwrap(fn() { panic })
}

fn parse_line(line: String) -> #(Int, List(Int)) {
  let assert [res, nums] = line |> string.split(": ")

  let res = parse_int(res)
  let nums = nums |> string.split(" ") |> list.map(parse_int)

  #(res, nums)
}

fn check_eq(
  res: Int,
  nums: List(Int),
  next_iter: fn(Int, Int) -> List(Int),
) -> Bool {
  let assert [first, ..rest] = nums
  let reachable_nums =
    list.fold(rest, [first], fn(acc, curr) {
      acc
      |> list.flat_map(next_iter(_, curr))
      |> list.filter(fn(x) { x <= res })
    })

  reachable_nums |> list.contains(res)
}

pub fn part1(input: String) -> Int {
  string.split(input, "\n")
  |> list.map(parse_line)
  |> list.filter(fn(x) { check_eq(x.0, x.1, fn(a, b) { [a + b, a * b] }) })
  |> list.map(fn(line) { line.0 })
  |> int.sum
}

fn concat(a: Int, b: Int) -> Int {
  parse_int(int.to_string(a) <> int.to_string(b))
}

pub fn part2(input: String) -> Int {
  string.split(input, "\n")
  |> list.map(parse_line)
  |> list.filter(fn(x) {
    check_eq(x.0, x.1, fn(a, b) { [a + b, a * b, concat(a, b)] })
  })
  |> list.map(fn(line) { line.0 })
  |> int.sum
}

pub fn main() {
  let input =
    simplifile.read("input.txt")
    |> result.lazy_unwrap(fn() { panic })
    |> string.trim

  io.println("Part 1: " <> string.inspect(part1(input)))
  io.println("Part 2: " <> string.inspect(part2(input)))
}
