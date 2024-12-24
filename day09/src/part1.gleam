import gleam/bool
import gleam/dict
import gleam/int
import gleam/list
import gleam/order

import shared.{type Block, File, Free, parse_input, partial_sum}

type State {
  Finished
  Started
}

type Acc {
  Acc(count: Int, next_idx: Int, seen: dict.Dict(Int, State))
}

fn add_acc(acc: Acc, id: Int, count: Int, finished: Bool) -> Acc {
  let end = acc.next_idx + count - 1
  let add = partial_sum(acc.next_idx, end) * id
  let state = case finished {
    True -> Finished
    False -> Started
  }

  Acc(acc.count + add, end + 1, dict.insert(acc.seen, id, state))
}

fn empty_acc() -> Acc {
  Acc(0, 0, dict.new())
}

fn fill_space(fwd: List(Block), rev: List(Block), acc: Acc) -> Acc {
  let assert [Free(space), ..fwd_rest] = fwd
  let assert [File(id, req), Free(free), ..rev_rest] = rev

  use <- bool.guard(dict.get(acc.seen, id) == Ok(Finished), return: acc)

  case int.compare(req, space) {
    order.Lt ->
      fill_space(
        [Free(space - req), ..fwd_rest],
        rev_rest,
        add_acc(acc, id, req, True),
      )

    order.Eq -> consume_block(fwd_rest, rev_rest, add_acc(acc, id, req, True))

    order.Gt ->
      consume_block(
        fwd_rest,
        [File(id, req - space), Free(free), ..rev_rest],
        add_acc(acc, id, space, False),
      )
  }
}

fn consume_block(fwd: List(Block), rev: List(Block), acc: Acc) -> Acc {
  let assert [File(id, req), ..fwd_rest] = fwd
  let assert [File(_, rev_req), ..] = rev

  use <- bool.guard(dict.get(acc.seen, id) == Ok(Finished), return: acc)
  use <- bool.guard(
    dict.get(acc.seen, id) == Ok(Started),
    return: add_acc(acc, id, int.min(req, rev_req), True),
  )

  fill_space(fwd_rest, rev, add_acc(acc, id, req, True))
}

pub fn part1(input: String) -> Int {
  let input = parse_input(input)
  let rev = input |> list.reverse

  consume_block(input, rev, empty_acc()).count
}
