import gleam/bool
import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/set
import gleam/string
import simplifile

type Coord {
  Coord(row: Int, col: Int)
}

type Direction {
  Up
  Down
  Left
  Right
}

fn all_dirs() -> List(Direction) {
  [Up, Down, Left, Right]
}

type Seen =
  dict.Dict(Coord, Bool)

type Map {
  Map(height: Int, width: Int, flowers: dict.Dict(Coord, String))
}

fn force_unwrap(res: Result(a, b)) -> a {
  result.lazy_unwrap(res, fn() { panic })
}

fn step(d: Direction) -> Coord {
  case d {
    Down -> Coord(row: 1, col: 0)
    Left -> Coord(row: 0, col: -1)
    Right -> Coord(row: 0, col: 1)
    Up -> Coord(row: -1, col: 0)
  }
}

fn move(c: Coord, d: Direction) -> Coord {
  let s = step(d)
  Coord(row: c.row + s.row, col: c.col + s.col)
}

fn read_map(input: String) -> Map {
  let lines = input |> string.split("\n")
  let height = lines |> list.length

  let width =
    lines
    |> list.first
    |> force_unwrap
    |> string.length

  let dict = {
    use acc, curr, row_idx <- list.index_fold(lines, dict.new())
    use acc, curr, col_idx <- list.index_fold(curr |> string.split(""), acc)

    let coord = Coord(row: row_idx, col: col_idx)
    use <- bool.lazy_guard(acc |> dict.has_key(coord), fn() { panic })

    dict.insert(acc, coord, curr)
  }

  Map(height, width, dict)
}

type FlowerExpansionState {
  FlowerExpansionState(seen: Seen, area: Int, perimeter: Int)
}

fn get_flower(
  map: Map,
  coord: Coord,
  else_return otherwise: a,
  then cont: fn(String) -> a,
) -> a {
  case map.flowers |> dict.get(coord) {
    Error(_) -> otherwise
    Ok(flower) -> cont(flower)
  }
}

fn inc_perimeter(state) {
  FlowerExpansionState(..state, perimeter: state.perimeter + 1)
}

fn inc_area(state) {
  FlowerExpansionState(..state, area: state.area + 1)
}

fn make_seen(state, coord) {
  FlowerExpansionState(..state, seen: dict.insert(state.seen, coord, True))
}

fn expand_flower(
  map: Map,
  flower: String,
  coord: Coord,
  state: FlowerExpansionState,
) -> FlowerExpansionState {
  use curr_flower <- get_flower(map, coord, else_return: inc_perimeter(state))
  use <- bool.guard(curr_flower != flower, return: inc_perimeter(state))

  use <- bool.guard(state.seen |> dict.has_key(coord), return: state)
  let state = state |> make_seen(coord) |> inc_area

  list.fold(all_dirs(), state, fn(state, dir) {
    let next_coord = move(coord, dir)
    expand_flower(map, flower, next_coord, state)
  })
}

fn count_areas(map: Map) -> Int {
  let #(states, _) = {
    use acc, coord, flower <- dict.fold(map.flowers, #([], dict.new()))
    let #(states, seen) = acc

    use <- bool.guard(seen |> dict.has_key(coord), return: acc)
    let state =
      expand_flower(map, flower, coord, FlowerExpansionState(seen, 0, 0))

    #([state, ..states], state.seen)
  }

  use acc, state <- list.fold(states, 0)
  acc + { state.area * state.perimeter }
}

pub fn part1(input: String) -> Int {
  let map = read_map(input)
  count_areas(map)
}

fn flood_plot(
  map: Map,
  flower: String,
  coord: Coord,
  plot: set.Set(Coord),
) -> set.Set(Coord) {
  use curr_flower <- get_flower(map, coord, else_return: plot)
  use <- bool.guard(
    curr_flower != flower || set.contains(plot, coord),
    return: plot,
  )

  list.fold(all_dirs(), set.insert(plot, coord), fn(plot, dir) {
    flood_plot(map, flower, move(coord, dir), plot)
  })
}

fn bounding_box(plot: set.Set(Coord)) -> #(Coord, Coord) {
  let reduce_by = fn(reduction: fn(Int, Int) -> Int) {
    set.to_list(plot)
    |> list.reduce(fn(a, b) {
      Coord(reduction(a.row, b.row), reduction(a.col, b.col))
    })
    |> force_unwrap
  }

  let min = reduce_by(fn(a, b) { int.min(a, b) })
  let max = reduce_by(fn(a, b) { int.max(a, b) })

  #(min, max)
}

type PlotSide {
  None
  East
  West
}

fn count_vertical_borders(plot: set.Set(Coord)) -> Int {
  let #(min, max) = bounding_box(plot)

  let count_along_col = fn(col: Int) {
    let #(count, _) =
      list.range(min.row, max.row)
      |> list.fold(#(0, None), fn(acc, row) {
        let #(count, last_plot_side) = acc
        let is_plot_left = set.contains(plot, Coord(row, col - 1))
        let is_plot_right = set.contains(plot, Coord(row, col))

        let new_plot_side = case is_plot_left, is_plot_right {
          True, False -> East
          False, True -> West
          _, _ -> None
        }

        let inc = case
          new_plot_side != last_plot_side && new_plot_side != None
        {
          True -> 1
          False -> 0
        }

        #(count + inc, new_plot_side)
      })

    count
  }

  list.range(min.col, max.col + 1)
  |> list.map(count_along_col)
  |> int.sum
}

fn count_borders(plot: set.Set(Coord)) -> Int {
  let vertical = count_vertical_borders(plot)
  let transposed_plot = set.map(plot, fn(c) { Coord(row: c.col, col: c.row) })
  let horizontal = count_vertical_borders(transposed_plot)

  vertical + horizontal
}

pub fn part2(input: String) -> Int {
  let map = read_map(input)

  let #(_, price) =
    dict.fold(map.flowers, #(set.new(), 0), fn(acc, coord, flower) {
      let #(seen, total_price) = acc
      use <- bool.guard(set.contains(seen, coord), return: acc)

      let plot = flood_plot(map, flower, coord, set.new())
      let area = set.size(plot)
      let count = count_borders(plot)
      let curr_price = count * area

      #(set.union(seen, plot), total_price + curr_price)
    })

  price
}

pub fn main() {
  let input =
    simplifile.read("input.txt")
    |> result.lazy_unwrap(fn() { panic })
    |> string.trim

  io.println("Part 1: " <> string.inspect(part1(input)))
  io.println("Part 2: " <> string.inspect(part2(input)))
}
