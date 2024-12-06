import gleam/bool
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/set
import gleam/string
import simplifile

type Reqs =
  set.Set(#(Int, Int))

fn force_unwrap(r: Result(a, e)) -> a {
  result.lazy_unwrap(r, fn() { panic })
}

fn parse_int(s: String) -> Int {
  int.parse(s) |> force_unwrap
}

fn make_requirements(lines: List(String)) -> Reqs {
  lines
  |> list.map(fn(line) {
    let assert [left, right] = string.split(line, "|") |> list.map(parse_int)
    #(left, right)
  })
  |> set.from_list
}

fn check_update(update: List(Int), reqs: Reqs) -> Bool {
  list.combination_pairs(update)
  |> list.all(fn(p) { !set.contains(reqs, #(p.1, p.0)) })
}

fn middle_element(l: List(a)) -> a {
  let len = list.length(l)
  use <- bool.lazy_guard(len % 2 == 1, otherwise: fn() { panic })

  let mid = len / 2
  list.drop(l, mid) |> list.first |> force_unwrap
}

type Input {
  Input(reqs: Reqs, good: List(List(Int)), bad: List(List(Int)))
}

fn parse_input(input: String) -> Input {
  let assert [rules, updates] =
    input
    |> string.split("\n\n")
    |> list.map(string.split(_, "\n"))

  let reqs = make_requirements(rules)

  let #(good, bad) =
    updates
    |> list.map(fn(update) { string.split(update, ",") |> list.map(parse_int) })
    |> list.partition(check_update(_, reqs))

  Input(reqs, good, bad)
}

pub fn part1(input: String) -> Int {
  parse_input(input).good
  |> list.map(middle_element)
  |> int.sum
}

type Acc {
  Acc(res: List(Int), seen: set.Set(Int))
}

// Recursive, dfs-based topsort 🤯
fn rec(update: List(Int), reqs: Reqs, curr_node: Int, acc: Acc) {
  use <- bool.guard(set.contains(acc.seen, curr_node), return: acc)
  let acc = Acc(..acc, seen: set.insert(acc.seen, curr_node))

  let acc =
    list.fold(update, acc, fn(acc, neigh) {
      use <- bool.guard(set.contains(reqs, #(neigh, curr_node)), return: acc)
      rec(update, reqs, neigh, acc)
    })

  Acc(..acc, res: [curr_node, ..acc.res])
}

fn reorder_update(update: List(Int), reqs: Reqs) -> List(Int) {
  list.fold(update, Acc([], set.new()), fn(acc, curr) {
    use <- bool.guard(set.contains(acc.seen, curr), return: acc)
    rec(update, reqs, curr, acc)
  }).res
}

pub fn part2(input: String) -> Int {
  let Input(reqs, _, bad) = parse_input(input)
  bad
  |> list.map(reorder_update(_, reqs))
  |> list.map(middle_element)
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
