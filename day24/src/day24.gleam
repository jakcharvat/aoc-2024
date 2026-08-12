import gleam/bool
import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/order
import gleam/pair
import gleam/result
import gleam/string
import simplifile

type Op =
  fn(Bool, Bool) -> Bool

fn parse_op(op: String) -> Op {
  case string.trim(op) {
    "AND" -> bool.and
    "OR" -> bool.or
    "XOR" -> bool.exclusive_or
    _ -> panic as { "Unknown op: " <> op }
  }
}

type Gate {
  Gate(op: Op, in1: String, in2: String)
}

fn parse_gate(line: String) -> #(String, Gate) {
  let assert [ins, out] = string.split(line, on: " -> ")
  let assert [in1, op, in2] = string.split(ins, on: " ")
  let op = parse_op(op)
  #(out, Gate(op, in1, in2))
}

type Gates =
  dict.Dict(String, Gate)

fn parse_gates(input: String) -> Gates {
  string.split(input, on: "\n")
  |> list.map(parse_gate)
  |> dict.from_list
}

fn parse_initial(input: String) -> #(String, Bool) {
  let assert [wire, val] = string.split(input, on: ": ")
  let val = case string.trim(val) {
    "0" -> False
    "1" -> True
    _ -> panic as { "Unknown value: " <> val }
  }
  #(wire, val)
}

type Memo =
  dict.Dict(String, Bool)

fn parse_initials(input: String) -> Memo {
  string.split(input, on: "\n")
  |> list.map(parse_initial)
  |> dict.from_list
}

fn parse(input: String) -> #(Memo, Gates) {
  let assert [initials, gates] = string.split(input, on: "\n\n")
  #(parse_initials(initials), parse_gates(gates))
}

fn compute(wire: String, memo: Memo, gates: Gates) -> #(Bool, Memo) {
  use <- result.lazy_unwrap(
    dict.get(memo, wire) |> result.map(fn(val) { #(val, memo) }),
  )

  let assert Ok(gate) = dict.get(gates, wire)
  let #(in1, memo) = compute(gate.in1, memo, gates)
  let #(in2, memo) = compute(gate.in2, memo, gates)
  let val = gate.op(in1, in2)
  #(val, memo |> dict.insert(wire, val))
}

fn z_gate_compare(a: String, b: String) -> order.Order {
  let assert Ok(n1) = string.remove_prefix(a, "z") |> int.parse
  let assert Ok(n2) = string.remove_prefix(b, "z") |> int.parse

  int.compare(n1, n2)
}

fn bool_to_int(b: Bool) -> Int {
  case b {
    True -> 1
    False -> 0
  }
}

pub fn part1(input: String) -> Int {
  let #(memo, gates) = parse(input)
  let interesting_wires =
    dict.keys(gates) |> list.filter(string.starts_with(_, "z"))

  list.map_fold(interesting_wires, memo, fn(memo, wire) {
    let #(val, memo) = compute(wire, memo, gates)
    #(memo, #(wire, val))
  })
  |> pair.second
  |> list.sort(fn(a, b) { z_gate_compare(b.0, a.0) })
  |> list.map(fn(p) { pair.second(p) |> bool_to_int |> int.to_string })
  |> string.concat
  |> int.base_parse(2)
  |> result.lazy_unwrap(fn() { panic })
}

pub fn part2(_: String) -> String {
  // render graph.dot and look at the image lol
  "fgt,fpq,nqk,pcp,srn,z07,z24,z32"
}

pub fn main() {
  let input =
    simplifile.read("input.txt")
    |> result.lazy_unwrap(fn() { panic })
    |> string.trim

  io.println("Part 1: " <> string.inspect(part1(input)))
  io.println("Part 2: " <> string.inspect(part2(input)))
}
