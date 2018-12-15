import * as R from 'ramda'
import { readInput } from '../utils'

interface IGrid {
  [propName: string]: number
}

const solveEx = (input: string[]) => {
  console.time('Solution')
  const grid: IGrid = Object.create({})
  for (const line of input) {
    const [num, at, one, two] = line.split(' ')
    const [left, top] = one
      .slice(0, -1)
      .split(',')
      .map((x: string) => Number(x))
    const [width, height] = two.split('x').map((x: string) => Number(x))
    for (let x = left; x < left + width; x++) {
      for (let y = top; y < top + height; y++) {
        const value = grid[`${x},${y}`] || 0
        grid[`${x},${y}`] = value + 1
      }
    }
  }
  const isGreaterThanOne = (x: number): boolean => x > 1
  const result = R.values(grid).filter(isGreaterThanOne).length
  console.timeEnd('Solution')
  return result
}

export const solve = () => {
  const day = '03'
  console.log(`--- Day ${day} (Part A) ---`)
  const input = readInput(day, 'input')
  const result = solveEx(input)
  console.log(result + '\n')
}
