import gleam/bool
import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/set
import gleam/string
import gleamy/priority_queue as pq
import simplifile

type Coord {
  Coord(x: Int, y: Int)
}

type Elem {
  Wall
  Start
  End
}

fn parse_elem(ch: String) -> Result(Elem, Nil) {
  case ch {
    "." -> Error(Nil)
    "#" -> Ok(Wall)
    "S" -> Ok(Start)
    "E" -> Ok(End)
    unk -> panic as { "Invalid maze character: '" <> unk <> "'" }
  }
}

type Maze {
  Maze(w: Int, h: Int, start: Coord, end: Coord, elems: dict.Dict(Coord, Elem))
}

fn enum2d(l: List(List(a))) -> List(#(Coord, a)) {
  list.index_map(l, fn(row, y) {
    list.index_map(row, fn(el, x) { #(Coord(x, y), el) })
  })
  |> list.flatten
}

fn parse(input: String) -> Maze {
  let grid =
    input
    |> string.trim()
    |> string.split("\n")
    |> list.map(fn(row) {
      row
      |> string.trim()
      |> string.split("")
    })

  let h = list.length(grid)
  let assert [first, ..] = grid
  let w = list.length(first)

  let blocks =
    grid
    |> enum2d
    |> list.filter_map(fn(p) {
      parse_elem(p.1) |> result.map(fn(el) { #(p.0, el) })
    })

  let assert [#(start, _)] = list.filter(blocks, fn(p) { p.1 == Start })
  let assert [#(end, _)] = list.filter(blocks, fn(p) { p.1 == End })
  let elems = dict.from_list(blocks)

  Maze(w:, h:, start:, end:, elems:)
}

type Dir {
  North
  South
  West
  East
}

fn dir_step(dir: Dir) -> Coord {
  case dir {
    North -> Coord(0, -1)
    South -> Coord(0, 1)
    West -> Coord(-1, 0)
    East -> Coord(1, 0)
  }
}

fn coord_step(coord: Coord, dir: Dir) -> Coord {
  Coord(coord.x + dir_step(dir).x, coord.y + dir_step(dir).y)
}

fn dir_left(dir: Dir) -> Dir {
  case dir {
    North -> West
    South -> East
    West -> South
    East -> North
  }
}

fn dir_right(dir: Dir) -> Dir {
  case dir {
    North -> East
    South -> West
    West -> North
    East -> South
  }
}

type Step {
  Step(coord: Coord, dir: Dir, dist: Int)
}

fn step_successors(step: Step) -> List(Step) {
  let Step(coord, dir, dist) = step
  [
    Step(coord_step(coord, dir), dir, dist + 1),
    Step(coord, dir_left(dir), dist + 1000),
    Step(coord, dir_right(dir), dist + 1000),
  ]
}

fn shortest_path_rec(
  maze: Maze,
  q: pq.Queue(Step),
  seen: dict.Dict(#(Coord, Dir), Int),
) -> Result(Int, Nil) {
  case pq.pop(q) {
    Ok(#(curr, q)) -> {
      case dict.get(maze.elems, curr.coord) {
        Ok(End) -> Ok(curr.dist)

        _ -> {
          let neighs = step_successors(curr)
          let #(q, seen) =
            list.fold(neighs, #(q, seen), fn(q_seen, next) {
              let #(q, seen) = q_seen

              let continue = case dict.get(maze.elems, next.coord) {
                Ok(Start) | Ok(End) | Error(_) -> {
                  case dict.get(seen, #(next.coord, next.dir)) {
                    Error(_) -> True
                    Ok(old_dist) if next.dist < old_dist -> True
                    _ -> False
                  }
                }
                _ -> False
              }

              case continue {
                True -> #(
                  pq.push(q, next),
                  dict.insert(seen, #(next.coord, next.dir), next.dist),
                )
                False -> q_seen
              }
            })

          shortest_path_rec(maze, q, seen)
        }
      }
    }

    Error(Nil) -> Error(Nil)
  }
}

fn shortest_path(maze: Maze) -> Int {
  let start = Step(maze.start, East, 0)

  let q_compare = fn(a: Step, b: Step) { int.compare(a.dist, b.dist) }
  let q = pq.from_list([start], q_compare)
  let seen = dict.from_list([#(#(start.coord, start.dir), start.dist)])

  shortest_path_rec(maze, q, seen)
  |> result.lazy_unwrap(fn() { panic as "Didn't find path to exit" })
}

pub fn part1(input: String) -> Int {
  let maze = parse(input)
  shortest_path(maze)
}

type MemStep {
  MemStep(coord: Coord, dir: Dir)
}

fn mem_step(step: Step) -> MemStep {
  MemStep(step.coord, step.dir)
}

type AllShortestSeen =
  dict.Dict(MemStep, #(Int, List(Step)))

fn all_shortest_paths_rec(
  maze: Maze,
  q: pq.Queue(Step),
  seen: AllShortestSeen,
) -> AllShortestSeen {
  case pq.pop(q) {
    Ok(#(curr, q)) -> {
      case dict.get(maze.elems, curr.coord) {
        // At this point, all paths that lead to end and have length <= curr.dist have been found
        // and written to `seen`, so I can just immediately stop and don't necessarily have to
        // continue popping from the queue.
        Ok(End) -> seen

        _ -> {
          let neighs = step_successors(curr)
          let #(q, seen) =
            list.fold(neighs, #(q, seen), fn(q_seen, next) {
              let #(q, seen) = q_seen

              let can_move = case dict.get(maze.elems, next.coord) {
                Ok(Wall) -> False
                _ -> True
              }
              use <- bool.guard(when: !can_move, return: q_seen)

              let save_shortest = fn() {
                #(
                  pq.push(q, next),
                  dict.insert(seen, mem_step(next), #(next.dist, [curr])),
                )
              }

              let save_same_length = fn(old_prev: List(Step)) {
                let new_prev = [curr, ..old_prev]
                #(q, dict.insert(seen, mem_step(next), #(next.dist, new_prev)))
              }

              case dict.get(seen, mem_step(next)) {
                Error(_) -> save_shortest()
                Ok(#(old_dist, _)) if next.dist < old_dist -> save_shortest()
                Ok(#(old_dist, old_prev)) if next.dist == old_dist ->
                  save_same_length(old_prev)
                _ -> #(q, seen)
              }
            })

          all_shortest_paths_rec(maze, q, seen)
        }
      }
    }

    Error(Nil) -> seen
  }
}

fn all_shortest_paths(maze: Maze) -> AllShortestSeen {
  let start = Step(maze.start, East, 0)

  let q_compare = fn(a: Step, b: Step) { int.compare(a.dist, b.dist) }
  let q = pq.from_list([start], q_compare)
  let seen = dict.from_list([#(mem_step(start), #(start.dist, [start]))])

  all_shortest_paths_rec(maze, q, seen)
}

fn shortest_path_tiles_rec(
  paths: AllShortestSeen,
  curr: MemStep,
) -> set.Set(Coord) {
  let assert Ok(#(_, prev)) = dict.get(paths, curr)
  let prev = list.filter(prev, fn(prev) { mem_step(prev) != curr })

  list.fold(prev, set.from_list([curr.coord]), fn(acc, prev) {
    let prev_shortest = shortest_path_tiles_rec(paths, mem_step(prev))
    set.union(acc, prev_shortest)
  })
}

fn shortest_path_tiles(paths: AllShortestSeen, coord: Coord) -> set.Set(Coord) {
  let direction_distances =
    [North, East, South, West]
    |> list.filter_map(fn(dir) {
      dict.get(paths, MemStep(coord, dir))
      |> result.map(fn(entry) { #(dir, entry.0) })
    })

  let shortest_distance =
    direction_distances
    |> list.map(fn(pair) { pair.1 })
    |> list.reduce(int.min)
    |> result.lazy_unwrap(fn() { panic as "No shortest path found" })

  let shortest_dirs =
    direction_distances
    |> list.filter(fn(pair) { pair.1 == shortest_distance })
    |> list.map(fn(pair) { pair.0 })

  shortest_dirs
  |> list.map(fn(dir) { shortest_path_tiles_rec(paths, MemStep(coord, dir)) })
  |> list.reduce(set.union)
  |> result.lazy_unwrap(fn() { panic as "No shortest path found" })
}

pub fn part2(input: String) -> Int {
  let maze = parse(input)

  all_shortest_paths(maze)
  |> shortest_path_tiles(maze.end)
  |> set.size
}

pub fn main() {
  let input =
    simplifile.read("input.txt")
    |> result.lazy_unwrap(fn() { panic })
    |> string.trim

  io.println("Part 1: " <> string.inspect(part1(input)))
  io.println("Part 2: " <> string.inspect(part2(input)))
}
