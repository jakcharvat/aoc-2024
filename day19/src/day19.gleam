import gleam/bool
import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import simplifile

type Towel =
  List(String)

type Input {
  Input(inventory: List(Towel), desired: List(Towel))
}

fn parse_towel(s: String) -> Towel {
  string.split(s, "")
}

fn parse(input: String) -> Input {
  let assert [inv, _, ..towels] = string.split(input, "\n")
  let inv = string.split(inv, ", ") |> list.map(parse_towel)
  let desired = list.map(towels, parse_towel)

  Input(inventory: inv, desired:)
}

fn list_starts_with(haystack: List(a), needle: List(a)) -> Bool {
  case haystack, needle {
    _, [] -> True
    [], _ -> False
    [h, ..haystack], [n, ..needle] ->
      h == n && list_starts_with(haystack, needle)
  }
}

fn can_make_rec(
  remaining_towel_rev: Towel,
  inventory: List(Towel),
  made: Towel,
  memo: dict.Dict(Int, Bool),
) -> Bool {
  case remaining_towel_rev {
    [] ->
      dict.get(memo, list.length(made)) |> result.lazy_unwrap(fn() { panic })
    [curr, ..remaining_towel_rev] -> {
      let made = [curr, ..made]
      let possible =
        list.any(inventory, fn(towel) {
          list_starts_with(made, towel)
          && dict.get(memo, list.length(made) - list.length(towel)) == Ok(True)
        })

      let memo = dict.insert(memo, list.length(made), possible)
      can_make_rec(remaining_towel_rev, inventory, made, memo)
    }
  }
}

fn can_make(towel: Towel, from available_towels: List(Towel)) -> Bool {
  let memo = dict.from_list([#(0, True)])
  can_make_rec(list.reverse(towel), available_towels, [], memo)
}

pub fn part1(input: String) -> Int {
  let input = parse(input)
  input.desired |> list.count(can_make(_, input.inventory))
}

fn count_options_rec(
  remaining_towel_rev: Towel,
  inventory: List(Towel),
  made: Towel,
  memo: dict.Dict(Int, Int),
) -> Int {
  case remaining_towel_rev {
    [] ->
      dict.get(memo, list.length(made)) |> result.lazy_unwrap(fn() { panic })
    [curr, ..remaining_towel_rev] -> {
      let made = [curr, ..made]
      let possibilities =
        list.map(inventory, fn(towel) {
          use <- bool.guard(when: !list_starts_with(made, towel), return: 0)
          dict.get(memo, list.length(made) - list.length(towel))
          |> result.unwrap(0)
        })
        |> int.sum

      let memo = dict.insert(memo, list.length(made), possibilities)
      count_options_rec(remaining_towel_rev, inventory, made, memo)
    }
  }
}

fn count_options(towel: Towel, from available_towels: List(Towel)) -> Int {
  let memo = dict.from_list([#(0, 1)])
  count_options_rec(list.reverse(towel), available_towels, [], memo)
}

pub fn part2(input: String) -> Int {
  let input = parse(input)
  input.desired |> list.map(count_options(_, input.inventory)) |> int.sum
}

pub fn main() {
  let input =
    simplifile.read("input.txt")
    |> result.lazy_unwrap(fn() { panic })
    |> string.trim

  io.println("Part 1: " <> string.inspect(part1(input)))
  io.println("Part 2: " <> string.inspect(part2(input)))
}
