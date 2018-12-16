import * as R from 'ramda'
import { readInput } from '../utils'

// This is given by the exercise and changes between sample and input
// const TOTAL_DISTANCE = 32 // for the small sample
const TOTAL_DISTANCE = 10_000 // for the real puzzle input

const toPairOfInt = ([xStr, yStr]: string[]): number[] => {
  const radix = 10
  return [parseInt(xStr, radix), parseInt(yStr, radix)]
}

const extractCoords = (str: string) => {
  const [xStr, yStr] = R.split(', ')(str)
  return toPairOfInt([xStr, yStr])
}

type SingleCoordFromPair = (list: number[]) => number
// type assertions to tell R.head and R.last that we are dealing numbers
const takeX = R.head as SingleCoordFromPair
const takeY = R.last as SingleCoordFromPair

interface IEntry {
  dist: number
  id: string
}

type ManhattanDistance = ([x0, y0]: number[], [x1, y1]: number[]) => number
const manhattanDistance: ManhattanDistance = ([x0, y0], [x1, y1]) => {
  return Math.abs(x0 - x1) + Math.abs(y0 - y1)
}
type PartiallyBoundManhattan = ([x1, y1]: number[]) => number
type PartialManhattan = (
  f: ManhattanDistance,
  args: number[][]
) => PartiallyBoundManhattan

const isInRegion = (e: IEntry) => e.dist < TOTAL_DISTANCE

export const solveEx = (input: string[]): number => {
  // Determine boundary
  const coords = R.map(extractCoords)(input)
  const xCoords = R.map(takeX)(coords)
  const yCoords = R.map(takeY)(coords)
  const [xMin, xMax] = R.juxt([Math.min, Math.max])(...xCoords)
  const [yMin, yMax] = R.juxt([Math.min, Math.max])(...yCoords)
  const [xCoordsBoundary, yCoordsBoundary] = [
    R.range(xMin, xMax + 1),
    R.range(yMin, yMax + 1),
  ]

  // Create a grid without using for loops
  const bindX = (x: number) => (y: number): number[] => [x, y]
  type BoundXFunction = ((y: number) => number[])
  const boundXFunctions: BoundXFunction[] = R.map(bindX)(xCoordsBoundary)
  const makeRow = (y: number) =>
    R.map((f: BoundXFunction) => f(y))(boundXFunctions)
  // grid is [][][] because: entire grid, single row, single point
  const grid: number[][][] = R.map(makeRow)(yCoordsBoundary)

  /**
   * Create a partially-bounded manhattan distance function for each point in
   * the grid (so if the grid is 2x3 we have 6 partially-bounded manhattan
   * functions). Each one of these partially-bounded manhattan function just
   * waits for the coordinate pair [x1, y1].
   */
  const partialManhattan = R.partial as PartialManhattan
  const bindManhattanToPoint = (point: number[]) =>
    partialManhattan(manhattanDistance, [point])
  const bindManhattanToRow = (row: number[][]) =>
    R.map(bindManhattanToPoint)(row)
  const boundManhattanFunctionsToGrid = R.map(bindManhattanToRow)(grid)

  const makeEntries = (partialMh: PartiallyBoundManhattan) => {
    const makeEntry = (point: number[]): IEntry => {
      return {
        dist: partialMh(point),
        id: `${point[0]}, ${point[1]}`,
      }
    }
    const arr = R.map(makeEntry)(coords)
    const reducer = (acc: IEntry, cv: IEntry): IEntry => {
      return { id: '', dist: acc.dist + cv.dist }
    }
    const d = arr.reduce(reducer, { id: '', dist: 0 })
    return d
  }

  // Type assertion for R.flatten
  type Flatten = (x: PartiallyBoundManhattan[][]) => PartiallyBoundManhattan[]
  const flatten = R.flatten as Flatten
  const manhattanFunctions = flatten(boundManhattanFunctionsToGrid)

  const candidateEntries = R.map(makeEntries)(manhattanFunctions)
  const finalEntries = R.filter(isInRegion)(candidateEntries)
  const result = finalEntries.length
  return result
}

export const solve = () => {
  const day = '06'
  console.log(`--- Day ${day} (Part B) ---`)
  const input = readInput(day, 'input')
  console.time('Solution')
  const result = solveEx(input)
  console.timeEnd('Solution')
  console.log(result + '\n')
}
