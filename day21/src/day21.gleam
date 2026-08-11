import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/order
import gleam/pair
import gleam/result
import gleam/string
import simplifile

type Coord {
  Coord(x: Int, y: Int)
}

type Move {
  Up
  Down
  Left
  Right
  Accept
}

fn all_moves() -> List(Move) {
  [Up, Down, Left, Right, Accept]
}

fn move_coord(move: Move) -> Coord {
  case move {
    Accept -> Coord(0, 0)
    Up -> Coord(1, 0)
    Down -> Coord(1, -1)
    Left -> Coord(2, -1)
    Right -> Coord(0, -1)
  }
}

fn coord_to_move_safe(coord: Coord) -> Result(Move, Nil) {
  case coord {
    Coord(0, 0) -> Ok(Accept)
    Coord(1, 0) -> Ok(Up)
    Coord(1, -1) -> Ok(Down)
    Coord(2, -1) -> Ok(Left)
    Coord(0, -1) -> Ok(Right)
    _ -> Error(Nil)
  }
}

type KeypadButton {
  KeypadAccept
  Zero
  One
  Two
  Three
  Four
  Five
  Six
  Seven
  Eight
  Nine
}

fn all_keypad_buttons() -> List(KeypadButton) {
  [
    KeypadAccept,
    Zero,
    One,
    Two,
    Three,
    Four,
    Five,
    Six,
    Seven,
    Eight,
    Nine,
  ]
}

fn keypad_coord(button: KeypadButton) -> Coord {
  case button {
    KeypadAccept -> Coord(0, 0)
    Zero -> Coord(x: 1, y: 0)
    One -> Coord(x: 2, y: 1)
    Two -> Coord(x: 1, y: 1)
    Three -> Coord(x: 0, y: 1)
    Four -> Coord(x: 2, y: 2)
    Five -> Coord(x: 1, y: 2)
    Six -> Coord(x: 0, y: 2)
    Seven -> Coord(x: 2, y: 3)
    Eight -> Coord(x: 1, y: 3)
    Nine -> Coord(x: 0, y: 3)
  }
}

fn coord_to_keypad_safe(coord: Coord) -> Result(KeypadButton, Nil) {
  case coord {
    Coord(0, 0) -> Ok(KeypadAccept)
    Coord(1, 0) -> Ok(Zero)
    Coord(2, 1) -> Ok(One)
    Coord(1, 1) -> Ok(Two)
    Coord(0, 1) -> Ok(Three)
    Coord(2, 2) -> Ok(Four)
    Coord(1, 2) -> Ok(Five)
    Coord(0, 2) -> Ok(Six)
    Coord(2, 3) -> Ok(Seven)
    Coord(1, 3) -> Ok(Eight)
    Coord(0, 3) -> Ok(Nine)
    _ -> Error(Nil)
  }
}

fn parse_keypad_button(button: String) -> KeypadButton {
  case button {
    "A" -> KeypadAccept
    "0" -> Zero
    "1" -> One
    "2" -> Two
    "3" -> Three
    "4" -> Four
    "5" -> Five
    "6" -> Six
    "7" -> Seven
    "8" -> Eight
    "9" -> Nine
    _ -> panic as { "Invalid button: " <> button }
  }
}

type Code {
  Code(buttons: List(KeypadButton), numerical_value: Int)
}

fn parse_code(line: String) -> Code {
  let buttons =
    string.trim(line) |> string.split("") |> list.map(parse_keypad_button)
  let num =
    string.remove_suffix(line, matching: "A")
    |> int.parse
    |> result.lazy_unwrap(fn() { panic as "Invalid number" })

  Code(buttons:, numerical_value: num)
}

fn parse(input: String) -> List(Code) {
  string.trim(input)
  |> string.split("\n")
  |> list.map(parse_code)
}

fn h_move(dx: Int) -> Move {
  case int.compare(dx, 0) {
    order.Eq -> Accept
    order.Gt -> Left
    order.Lt -> Right
  }
}

fn v_move(dy: Int) -> Move {
  case int.compare(dy, 0) {
    order.Eq -> Accept
    order.Gt -> Up
    order.Lt -> Down
  }
}

fn all_pairs(of list: List(a)) -> List(#(a, a)) {
  list
  |> list.flat_map(fn(from) { list.map(list, fn(to) { #(from, to) }) })
}

fn optimize(
  moves: Dict(#(Move, Move), Int),
  buttons: List(button),
  button_to_coord: fn(button) -> Coord,
  can_use: fn(Coord) -> Bool,
) -> Dict(#(button, button), Int) {
  all_pairs(buttons)
  |> list.map(fn(pair) {
    let #(from, to) = pair
    let #(from_coord, to_coord) = #(button_to_coord(from), button_to_coord(to))

    let dx = to_coord.x - from_coord.x
    let dy = to_coord.y - from_coord.y

    let cost = fn(from: Move, to: Move) -> Int {
      dict.get(moves, #(from, to))
      |> result.lazy_unwrap(fn() {
        panic as { "Missing cost for move " <> string.inspect(#(from, to)) }
      })
    }

    let #(h, v) = #(h_move(dx), v_move(dy))
    let hv_corner = Coord(from_coord.x + dx, from_coord.y)
    let vh_corner = Coord(from_coord.x, from_coord.y + dy)

    let dx = int.absolute_value(dx)
    let dy = int.absolute_value(dy)

    let hv_cost = cost(Accept, h) + cost(h, v) + cost(v, Accept)
    let vh_cost = cost(Accept, v) + cost(v, h) + cost(h, Accept)

    let cost =
      case can_use(hv_corner), can_use(vh_corner) {
        True, True -> int.min(hv_cost, vh_cost)
        True, False -> hv_cost
        False, True -> vh_cost
        False, False ->
          panic as {
            "No move from "
            <> string.inspect(from)
            <> " to "
            <> string.inspect(to)
          }
      }
      + { dx + dy - 2 }

    #(pair, cost)
  })
  |> dict.from_list
}

fn optimize_moves(moves: Dict(#(Move, Move), Int)) -> Dict(#(Move, Move), Int) {
  optimize(moves, all_moves(), move_coord, fn(coord) {
    coord_to_move_safe(coord) |> result.is_ok
  })
}

fn optimize_keypad(
  moves: Dict(#(Move, Move), Int),
) -> Dict(#(KeypadButton, KeypadButton), Int) {
  optimize(moves, all_keypad_buttons(), keypad_coord, fn(coord) {
    coord_to_keypad_safe(coord) |> result.is_ok
  })
}

fn best_keypad_moves(
  arrow_reps: Int,
) -> Dict(#(KeypadButton, KeypadButton), Int) {
  let manual_cost =
    all_pairs(all_moves())
    |> list.map(fn(pair) { #(pair, 1) })
    |> dict.from_list

  manual_cost
  |> int.range(0, arrow_reps, _, fn(acc, _) { optimize_moves(acc) })
  |> optimize_keypad
}

fn solve_code(
  code: Code,
  keypad_moves: Dict(#(KeypadButton, KeypadButton), Int),
) -> Int {
  let cost =
    list.map_fold(code.buttons, KeypadAccept, fn(curr, next) {
      let cost =
        dict.get(keypad_moves, #(curr, next))
        |> result.lazy_unwrap(fn() {
          panic as {
            "No cost for keypad move from "
            <> string.inspect(curr)
            <> " to "
            <> string.inspect(next)
          }
        })
      #(next, cost)
    })
    |> pair.second
    |> int.sum

  cost * code.numerical_value
}

pub fn part1(input: String) -> Int {
  let codes = parse(input)
  let keypad_moves = best_keypad_moves(2)

  codes
  |> list.map(solve_code(_, keypad_moves))
  |> int.sum
}

pub fn part2(input: String) -> Int {
  let codes = parse(input)
  let keypad_moves = best_keypad_moves(25)

  codes
  |> list.map(solve_code(_, keypad_moves))
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
