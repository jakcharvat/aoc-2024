import gleam/int
import gleam/io
import gleam/list
import gleam/regexp
import gleam/result
import gleam/string
import simplifile

const needle = "XMAS"

type Ws =
  List(List(String))

type Mat(a) =
  List(List(a))

fn to_char_arr(input: String) -> Ws {
  input
  |> string.split("\n")
  |> list.map(string.split(_, ""))
}

/// Return the main diagonal and all the diagonals above it
fn top_diagonals(ws: Ws) -> List(String) {
  ws
  |> list.index_map(fn(row, i) { list.drop(row, i) })
  |> list.transpose
  |> list.map(string.join(_, ""))
}

/// Return all diagonals below the main diagonal
fn bottom_diagonals(ws: Ws) -> List(String) {
  ws
  |> list.index_map(fn(row, i) { list.take(row, i) })
  |> list.map(list.reverse)
  |> list.transpose
  |> list.map(string.join(_, ""))
}

fn diagonals(ws: Ws) -> List(String) {
  [top_diagonals(ws), bottom_diagonals(ws)] |> list.flatten
}

fn rows(ws: Ws) -> List(String) {
  ws |> list.map(string.join(_, ""))
}

fn all_lines(ws: Ws) -> List(String) {
  [
    rows(ws),
    rows(ws |> list.transpose),
    diagonals(ws),
    diagonals(ws |> list.reverse),
  ]
  |> list.flatten
  |> list.flat_map(fn(line) { [line, string.reverse(line)] })
}

fn count_needle(in haystack: String) -> Int {
  let re = regexp.from_string(needle) |> result.lazy_unwrap(fn() { panic })
  regexp.scan(re, haystack) |> list.length
}

pub fn part1(input: String) -> Int {
  to_char_arr(input)
  |> all_lines
  |> list.map(count_needle)
  |> int.sum
}

pub fn window_2d(l: Mat(a), len: Int) -> Mat(Mat(a)) {
  l
  |> list.window(len)
  |> list.map(fn(w) {
    w |> list.transpose |> list.window(len) |> list.map(list.transpose)
  })
}

fn is_x_mas(window: Mat(String)) -> Bool {
  case window {
    [["M", _, "S"], [_, "A", _], ["M", _, "S"]] -> True
    [["S", _, "M"], [_, "A", _], ["S", _, "M"]] -> True
    [["M", _, "M"], [_, "A", _], ["S", _, "S"]] -> True
    [["S", _, "S"], [_, "A", _], ["M", _, "M"]] -> True
    _ -> False
  }
}

pub fn part2(input: String) -> Int {
  to_char_arr(input)
  |> window_2d(3)
  |> list.flatten
  |> list.filter(is_x_mas)
  |> list.length
}

pub fn main() {
  let input =
    simplifile.read("input.txt")
    |> result.lazy_unwrap(fn() { panic })
    |> string.trim

  io.println("Part 1: " <> string.inspect(part1(input)))
  io.println("Part 2: " <> string.inspect(part2(input)))
}
