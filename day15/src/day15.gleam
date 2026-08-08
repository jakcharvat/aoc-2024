import gleam/bool
import gleam/dict
import gleam/function
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/set
import gleam/string
import simplifile

type Coord {
  Coord(x: Int, y: Int)
}

type Maze {
  Maze(w: Int, h: Int, bot: Coord, walls: set.Set(Coord), boxes: set.Set(Coord))
}

type Maze2 {
  Maze2(
    w: Int,
    h: Int,
    bot: Coord,
    walls: set.Set(Coord),
    boxes: dict.Dict(Coord, Int),
  )
}

type Move {
  Left
  Right
  Up
  Down
}

type Input(maze) {
  Input(maze: maze, moves: List(Move))
}

type Elem(box_neigh) {
  Wall
  Bot
  Box(neigh: box_neigh)
}

fn parse_elem(c: String) -> Result(Elem(Nil), Nil) {
  case c {
    "#" -> Ok(Wall)
    "@" -> Ok(Bot)
    "O" -> Ok(Box(Nil))
    "." -> Error(Nil)
    _ -> panic as { "Invalid element: " <> c }
  }
}

fn parse_maze(input: String) -> Maze {
  let lines = string.trim(input) |> string.split("\n")

  let h = list.length(lines)
  let assert [first, ..] = lines
  let w = string.length(first)

  let blocks =
    lines
    |> list.index_map(fn(line, y) {
      string.trim(line)
      |> string.split("")
      |> list.index_map(fn(c, x) {
        parse_elem(c) |> result.map(fn(elem) { #(elem, Coord(x, y)) })
      })
      |> list.filter_map(function.identity)
    })
    |> list.flatten()

  let assert [bot] = list.filter(blocks, fn(box) { box.0 == Bot })
  let bot = bot.1

  let walls =
    list.filter(blocks, fn(box) { box.0 == Wall })
    |> list.map(fn(box) { box.1 })
    |> set.from_list

  let boxes =
    list.filter(blocks, fn(box) { box.0 == Box(Nil) })
    |> list.map(fn(box) { box.1 })
    |> set.from_list

  Maze(w, h, bot, walls, boxes)
}

fn parse_move(input: String) -> Move {
  case input {
    ">" -> Right
    "<" -> Left
    "v" -> Down
    "^" -> Up
    _ -> panic as { "Invalid move: " <> input }
  }
}

fn parse(input: String, parse_maze: fn(String) -> maze) -> Input(maze) {
  let assert [maze, moves] = string.split(input, "\n\n")

  let maze = parse_maze(maze)

  let moves =
    moves
    |> string.trim()
    |> string.split("\n")
    |> list.flat_map(fn(line) {
      line |> string.trim |> string.split("") |> list.map(parse_move)
    })

  Input(maze, moves)
}

fn maze_show(maze: Maze) -> String {
  int.range(0, maze.h, "", fn(acc, y) {
    acc
    <> int.range(0, maze.w, "", fn(acc, x) {
      let c = Coord(x, y)
      acc
      <> {
        use <- bool.guard(when: set.contains(maze.walls, c), return: "#")
        use <- bool.guard(when: set.contains(maze.boxes, c), return: "O")
        use <- bool.guard(when: c == maze.bot, return: "@")
        "."
      }
    })
    <> "\n"
  })
}

fn move_coord(move: Move) -> Coord {
  case move {
    Left -> Coord(-1, 0)
    Right -> Coord(1, 0)
    Up -> Coord(0, -1)
    Down -> Coord(0, 1)
  }
}

fn coord_step(c: Coord, dir: Move) -> Coord {
  coord_add(c, move_coord(dir))
}

fn coord_add(c1: Coord, c2: Coord) -> Coord {
  Coord(c1.x + c2.x, c1.y + c2.y)
}

fn free_spot(maze: Maze, from_coord: Coord, dir: Move) -> Result(Coord, Nil) {
  let neigh = coord_step(from_coord, dir)
  assert neigh.x >= 0 && neigh.x < maze.w
  assert neigh.y >= 0 && neigh.y < maze.h

  use <- bool.guard(when: set.contains(maze.walls, neigh), return: Error(Nil))
  use <- bool.guard(when: !set.contains(maze.boxes, neigh), return: Ok(neigh))
  free_spot(maze, neigh, dir)
}

fn maze_move(maze: Maze, dir: Move) -> Maze {
  case free_spot(maze, maze.bot, dir) {
    Error(_) -> maze
    Ok(free_spot) -> {
      let neigh = coord_step(maze.bot, dir)
      Maze(
        maze.w,
        maze.h,
        neigh,
        walls: maze.walls,
        boxes: maze.boxes |> set.insert(free_spot) |> set.delete(neigh),
      )
    }
  }
}

fn coord_gps(c: Coord) -> Int {
  100 * c.y + c.x
}

pub fn part1(input: String) -> Int {
  let Input(maze, moves) = parse(input, parse_maze)
  maze_show(maze) |> io.println

  let end_maze =
    list.fold(moves, maze, fn(maze, move) { maze_move(maze, move) })
  maze_show(end_maze) |> io.println

  end_maze.boxes |> set.to_list |> list.map(coord_gps) |> int.sum
}

fn parse_maze2(input: String) -> Maze2 {
  let lines = string.trim(input) |> string.split("\n")

  let h = list.length(lines)
  let assert [first, ..] = lines
  let w = string.length(first) * 2

  let blocks =
    lines
    |> list.index_map(fn(line, y) {
      string.trim(line)
      |> string.split("")
      |> list.index_map(fn(c, x) {
        parse_elem(c) |> result.map(fn(elem) { #(elem, Coord(2 * x, y)) })
      })
      |> list.filter_map(function.identity)
    })
    |> list.flatten()

  let assert [bot] = list.filter(blocks, fn(box) { box.0 == Bot })
  let bot = bot.1

  let walls =
    list.filter(blocks, fn(box) { box.0 == Wall })
    |> list.flat_map(fn(box) { [box.1, coord_step(box.1, Right)] })
    |> set.from_list

  let boxes =
    list.filter(blocks, fn(box) { box.0 == Box(Nil) })
    |> list.flat_map(fn(box) {
      let Coord(x, y) = box.1
      [#(Coord(x, y), x + 1), #(Coord(x + 1, y), x)]
    })
    |> dict.from_list

  Maze2(w, h, bot, walls, boxes)
}

fn guard_box(maze: Maze2, c: Coord, f: fn() -> String) -> String {
  case dict.get(maze.boxes, c) {
    Ok(neigh) -> {
      case neigh - c.x + 1 {
        0 -> "]"
        2 -> "["
        _ ->
          panic as {
            "Boxes have gone weird: "
            <> int.to_string(c.x)
            <> "'s neighbour is "
            <> int.to_string(neigh)
          }
      }
    }
    Error(_) -> f()
  }
}

fn maze2_show(maze: Maze2) -> String {
  int.range(0, maze.h, "", fn(acc, y) {
    acc
    <> int.range(0, maze.w, "", fn(acc, x) {
      let c = Coord(x, y)
      acc
      <> {
        use <- bool.guard(when: set.contains(maze.walls, c), return: "#")
        use <- guard_box(maze, c)
        use <- bool.guard(when: c == maze.bot, return: "@")
        "."
      }
    })
    <> "\n"
  })
}

fn maze2_get(maze: Maze2, c: Coord) -> option.Option(Elem(Int)) {
  use <- bool.guard(when: set.contains(maze.walls, c), return: Some(Wall))
  use <- bool.guard(when: c == maze.bot, return: Some(Bot))

  case dict.get(maze.boxes, c) {
    Error(_) -> None
    Ok(sibling) -> Some(Box(sibling))
  }
}

fn maze2_move_h(maze: Maze2, c: Coord, step: Int) -> Maze2 {
  assert int.absolute_value(step) == 1
  let neigh = Coord(c.x + step, c.y)

  let move = fn(maze: Maze2) -> Maze2 {
    case maze2_get(maze, neigh) {
      None -> Nil
      other ->
        panic as {
          "Attempting to move to non-empty block " <> string.inspect(other)
        }
    }

    case maze2_get(maze, c) {
      Some(Box(sibling)) -> {
        Maze2(
          ..maze,
          boxes: maze.boxes
            |> dict.delete(c)
            |> dict.insert(neigh, sibling + step),
        )
      }
      Some(Bot) -> Maze2(..maze, bot: neigh)

      Some(Wall) -> panic as "Attempting to move wall!"
      None -> panic as "Attempting to move empty space!"
    }
  }

  case maze2_get(maze, neigh) {
    Some(Wall) -> maze
    None -> move(maze)
    Some(Bot) -> panic as "Trying to move to bot position!"
    Some(Box(_)) -> {
      let maze = maze2_move_h(maze, neigh, step)
      case maze2_get(maze, neigh) {
        Some(Wall) -> maze
        Some(Box(_)) -> maze
        Some(Bot) -> panic as "Trying to move to bot position!"
        None -> move(maze)
      }
    }
  }
}

fn can_move(maze: Maze2, c: Coord, step: Int) -> Bool {
  let neigh = Coord(c.x, c.y + step)
  case maze2_get(maze, neigh) {
    None -> True
    Some(Wall) -> False
    Some(Bot) -> panic as "Trying to move to bot position!"
    Some(Box(sibling)) -> {
      can_move(maze, neigh, step)
      && can_move(maze, Coord(x: sibling, y: neigh.y), step)
    }
  }
}

fn move_v(maze: Maze2, c: Coord, step: Int) -> Maze2 {
  let neigh_y = c.y + step
  let maze = case maze2_get(maze, c) {
    Some(Bot) -> move_v(maze, Coord(c.x, neigh_y), step)
    Some(Box(sibling)) -> {
      maze
      |> move_v(Coord(x: c.x, y: neigh_y), step)
      |> move_v(Coord(x: sibling, y: neigh_y), step)
    }

    None -> maze
    Some(Wall) -> panic as "Attempting to move wall!"
  }

  case maze2_get(maze, c) {
    Some(Bot) -> Maze2(..maze, bot: Coord(c.x, neigh_y))
    Some(Box(sibling)) -> {
      Maze2(
        ..maze,
        boxes: maze.boxes
          |> dict.delete(c)
          |> dict.delete(Coord(x: sibling, y: c.y))
          |> dict.insert(Coord(x: c.x, y: neigh_y), sibling)
          |> dict.insert(Coord(x: sibling, y: neigh_y), c.x),
      )
    }

    None -> maze
    Some(Wall) -> panic as "Attempting to move wall!"
  }
}

fn maze2_move_v(maze: Maze2, c: Coord, step: Int) -> Maze2 {
  case can_move(maze, c, step) {
    False -> maze
    True -> move_v(maze, c, step)
  }
}

pub fn part2(input: String) -> Int {
  let Input(maze, moves) = parse(input, parse_maze2)
  maze2_show(maze) |> io.println

  let end_maze =
    list.fold(moves, maze, fn(maze, move) {
      case move {
        Up -> maze2_move_v(maze, maze.bot, -1)
        Down -> maze2_move_v(maze, maze.bot, 1)
        Left -> maze2_move_h(maze, maze.bot, -1)
        Right -> maze2_move_h(maze, maze.bot, 1)
      }
    })
  maze2_show(end_maze) |> io.println

  end_maze.boxes
  |> dict.filter(fn(c, sibling) { c.x == sibling - 1 })
  |> dict.keys
  |> list.map(coord_gps)
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
