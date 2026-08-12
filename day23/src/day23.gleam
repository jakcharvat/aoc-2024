import gleam/bool
import gleam/dict
import gleam/function
import gleam/int
import gleam/io
import gleam/list
import gleam/pair
import gleam/result
import gleam/set
import gleam/string
import simplifile

type Edge =
  #(String, String)

type Edges =
  set.Set(Edge)

fn parse_edge(line: String) -> Edge {
  let assert [a, b] = string.split(line, "-")
  #(a, b)
}

fn parse_graph(input: String) -> #(List(String), Edges) {
  let edges =
    string.split(input, "\n")
    |> list.map(parse_edge)

  let nodes =
    edges
    |> list.flat_map(fn(pair) {
      let #(a, b) = pair
      [a, b]
    })
    |> list.unique

  let edges =
    edges
    |> list.flat_map(fn(pair) {
      let #(a, b) = pair
      [#(a, b), #(b, a)]
    })
    |> set.from_list

  #(nodes, edges)
}

fn is_chief(node: String) -> Bool {
  string.starts_with(node, "t")
}

pub fn part1(input: String) -> Int {
  let #(nodes, edges) = parse_graph(input)
  list.combinations(nodes, 3)
  |> list.count(fn(triple) {
    let assert [a, b, c] = triple
    let is_connected =
      list.all([#(a, b), #(b, c), #(c, a)], set.contains(edges, _))
    let has_chief = list.any([a, b, c], is_chief)

    is_connected && has_chief
  })
}

fn count_degrees(edges: Edges) -> dict.Dict(Int, Int) {
  edges
  |> set.to_list
  |> list.group(pair.first)
  |> dict.values
  |> list.map(list.length)
  |> list.group(function.identity)
  |> dict.map_values(fn(_, values) { list.length(values) })
}

type Neighbours =
  dict.Dict(String, set.Set(String))

fn largest_clique(
  neighbours: Neighbours,
  clique: List(String),
  candidates: set.Set(String),
) -> List(String) {
  set.to_list(candidates)
  |> list.fold(#(clique, set.new()), fn(acc, candidate) {
    let #(largest, seen) = acc
    let new_seen = set.insert(seen, candidate)

    let new_clique = [candidate, ..clique]
    let candidate_neighbours =
      dict.get(neighbours, candidate)
      |> result.lazy_unwrap(fn() { panic })
      |> set.difference(seen)

    let new_candidates = set.intersection(candidates, candidate_neighbours)
    let new_clique_max_size = list.length(new_clique) + set.size(new_candidates)
    use <- bool.guard(
      when: new_clique_max_size <= list.length(largest),
      return: #(largest, new_seen),
    )

    let new_clique = largest_clique(neighbours, new_clique, new_candidates)
    let new_clique = case list.length(new_clique) > list.length(largest) {
      True -> new_clique
      False -> largest
    }

    #(new_clique, new_seen)
  })
  |> pair.first
}

fn neighbours(edges: Edges) -> Neighbours {
  set.to_list(edges)
  |> list.group(pair.first)
  |> dict.map_values(fn(_, value) {
    list.map(value, pair.second) |> set.from_list
  })
}

pub fn part2(input: String) -> String {
  let #(nodes, edges) = parse_graph(input)
  echo count_degrees(edges)

  let neighbours = neighbours(edges)
  list.map_fold(nodes, set.new(), fn(seen, node) {
    let candidates =
      dict.get(neighbours, node)
      |> result.lazy_unwrap(fn() { panic })
      |> set.difference(seen)

    #(set.insert(seen, node), largest_clique(neighbours, [node], candidates))
  })
  |> pair.second
  |> list.max(fn(a, b) { int.compare(list.length(a), list.length(b)) })
  |> result.lazy_unwrap(fn() { panic })
  |> list.sort(string.compare)
  |> string.join(",")
}

pub fn main() {
  let input =
    simplifile.read("input.txt")
    |> result.lazy_unwrap(fn() { panic })
    |> string.trim

  io.println("Part 1: " <> string.inspect(part1(input)))
  io.println("Part 2: " <> string.inspect(part2(input)))
}
