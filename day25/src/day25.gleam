import gleam/io
import gleam/list
import gleam/result
import gleam/string
import simplifile

type Kind {
  Key
  Lock
}

type Pic =
  List(Int)

fn height(schematic: List(List(String))) -> Pic {
  case schematic {
    [] -> []
    [head, ..rest] -> {
      let h = list.count(head, fn(ch) { ch == "#" })
      [h, ..height(rest)]
    }
  }
}

fn parse_block(input: String) -> #(Kind, Pic) {
  let assert [top, ..rest] = string.split(input, "\n")
  let assert [_, ..mid] = list.reverse(rest)

  let assert [top_front, ..] = string.split(top, "")

  let kind = case top_front {
    "#" -> Lock
    "." -> Key
    _ -> panic as { "invalid top front character: " <> top_front }
  }

  let heights =
    list.map(mid, string.split(_, on: ""))
    |> list.transpose
    |> height

  #(kind, heights)
}

type Input {
  Input(keys: List(Pic), locks: List(Pic))
}

fn parse(input: String) -> Input {
  string.split(input, "\n\n")
  |> list.map(parse_block)
  |> list.reverse
  |> list.fold(Input(keys: [], locks: []), fn(input, block) {
    case block.0 {
      Key -> Input(keys: [block.1, ..input.keys], locks: input.locks)
      Lock -> Input(keys: input.keys, locks: [block.1, ..input.locks])
    }
  })
}

fn key_lock_pairs(input: Input) -> List(#(Pic, Pic)) {
  let Input(keys:, locks:) = input
  list.flat_map(keys, fn(key) { list.map(locks, fn(lock) { #(key, lock) }) })
}

fn can_fit(pair: #(Pic, Pic)) -> Bool {
  let #(key, lock) = pair
  list.zip(key, lock)
  |> list.map(fn(pair) { pair.0 + pair.1 })
  |> list.all(fn(height) { height <= 5 })
}

pub fn part1(input: String) -> Int {
  parse(input) |> key_lock_pairs |> list.count(can_fit)
}

pub fn main() {
  let input =
    simplifile.read("input.txt")
    |> result.lazy_unwrap(fn() { panic })
    |> string.trim

  io.println("Part 1: " <> string.inspect(part1(input)))
}
