import gleam/bool
import gleam/dict
import gleam/function
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/set
import gleam/string
import simplifile

pub type CheatTally {
  CheatTally(time_saved: Int, count: Int)
}

type Coord {
  Coord(x: Int, y: Int)
}

fn coord_add(a: Coord, b: Coord) -> Coord {
  Coord(x: a.x + b.x, y: a.y + b.y)
}

fn manhattan(a: Coord, b: Coord) -> Int {
  int.absolute_value(a.x - b.x) + int.absolute_value(a.y - b.y)
}

fn steps() -> List(Coord) {
  [
    Coord(x: 0, y: 1),
    Coord(x: 1, y: 0),
    Coord(x: 0, y: -1),
    Coord(x: -1, y: 0),
  ]
}

fn neighbours(of coord: Coord) -> List(Coord) {
  list.map(steps(), coord_add(_, coord))
}

type Maze {
  Maze(
    width: Int,
    height: Int,
    start: Coord,
    end: Coord,
    path: dict.Dict(Coord, Int),
  )
}

type Block {
  Wall
  Start
  End
  Path
}

fn load_maze(input: String) -> Maze {
  let lines =
    string.trim(input)
    |> string.split("\n")
    |> list.map(string.split(_, on: ""))

  let assert [first, ..] = lines
  let height = list.length(lines)
  let width = list.length(first)

  let blocks =
    list.index_map(lines, fn(row, y) {
      list.index_map(row, fn(cell, x) {
        let block = case cell {
          "." -> Path
          "#" -> Wall
          "S" -> Start
          "E" -> End
          _ -> panic as { "Unexpected cell: " <> cell }
        }

        #(Coord(x:, y:), block)
      })
    })
    |> list.flatten
    |> list.filter(fn(block) { block.1 != Wall })

  let assert [#(start, _)] = list.filter(blocks, fn(block) { block.1 == Start })
  let assert [#(end, _)] = list.filter(blocks, fn(block) { block.1 == End })

  let path_tiles = list.map(blocks, fn(block) { block.0 })
  let path = enumerate_path(path_tiles, start)

  Maze(width:, height:, start:, end:, path:)
}

fn enumerate_path(
  path: List(Coord),
  from_coord: Coord,
) -> dict.Dict(Coord, Int) {
  let path = set.from_list(path)

  let #(dists, _, _) =
    int.range(
      0,
      set.size(path),
      #(dict.new(), from_coord, from_coord),
      fn(acc, _) {
        let #(dists, curr, prev) = acc
        let dists = dict.insert(dists, curr, dict.size(dists))

        let next =
          list.map(steps(), coord_add(curr, _))
          |> list.filter(fn(neigh) {
            neigh != prev && set.contains(path, neigh)
          })

        case next {
          [] -> #(dists, curr, prev)
          [next] -> #(dists, next, curr)
          _ ->
            panic as { "multiple successors of tile " <> string.inspect(curr) }
        }
      },
    )

  assert dict.size(dists) == set.size(path)
  dists
}

fn show_maze(maze: Maze) -> String {
  int.range(0, maze.height, "", fn(out, y) {
    out
    <> int.range(0, maze.width, "", fn(out, x) {
      let coord = Coord(x:, y:)
      let char = {
        use <- bool.guard(when: coord == maze.start, return: "S")
        use <- bool.guard(when: coord == maze.end, return: "E")
        case dict.get(maze.path, coord) {
          Ok(dist) -> int.to_string(dist % 10)
          Error(_) -> "#"
        }
      }

      out <> char
    })
    <> "\n"
  })
}

pub fn tally_cheats(input: String) -> List(CheatTally) {
  let maze = load_maze(input)
  show_maze(maze) |> io.println

  let tally =
    list.flat_map(dict.to_list(maze.path), fn(start) {
      let #(start_coord, start_dist) = start

      neighbours(start_coord)
      |> list.filter(fn(neigh) { !dict.has_key(maze.path, neigh) })
      |> list.flat_map(fn(wall) {
        neighbours(wall)
        |> list.filter_map(fn(neigh) {
          case dict.get(maze.path, neigh) {
            Ok(dist) if dist > start_dist -> Ok(dist - start_dist - 2)
            _ -> Error(Nil)
          }
        })
      })
    })
    |> list.group(function.identity)
    |> dict.map_values(fn(_, l) { list.length(l) })

  dict.to_list(tally)
  |> list.map(fn(entry) { CheatTally(time_saved: entry.0, count: entry.1) })
  |> list.filter(fn(cheat) { cheat.time_saved > 0 })
}

pub fn part1(input: String) -> Int {
  tally_cheats(input)
  |> list.filter(fn(cheat) { cheat.time_saved >= 100 })
  |> list.map(fn(cheat) { cheat.count })
  |> int.sum
}

pub fn tally_long_cheats(
  input: String,
  strength_threshold: Int,
) -> List(CheatTally) {
  let maze = load_maze(input)

  let tally =
    list.flat_map(dict.to_list(maze.path), fn(start) {
      dict.to_list(maze.path)
      |> list.filter(fn(end) {
        start.1 < end.1 && manhattan(start.0, end.0) <= 20
      })
      |> list.map(fn(end) { end.1 - start.1 - manhattan(start.0, end.0) })
      |> list.filter(fn(time_saved) { time_saved >= strength_threshold })
    })
    |> list.group(function.identity)
    |> dict.map_values(fn(_, l) { list.length(l) })

  dict.to_list(tally)
  |> list.map(fn(entry) { CheatTally(time_saved: entry.0, count: entry.1) })
  |> list.filter(fn(cheat) { cheat.time_saved > 0 })
}

pub fn part2(input: String) -> Int {
  tally_long_cheats(input, 100)
  |> list.map(fn(cheat) { cheat.count })
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
