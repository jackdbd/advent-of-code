import * as R from 'ramda'
import { readInput } from '../utils'

interface IGrid {
  [propName: string]: string
}

interface IClaims {
  [propName: string]: boolean
}

const solveEx = (input: string[]) => {
  console.time('Solution')
  const grid: IGrid = Object.create({})
  const claims: IClaims = Object.create({})

  for (const line of input) {
    const [num, at, one, two] = line.split(' ')
    const [left, top] = one
      .slice(0, -1)
      .split(',')
      .map((x: string) => Number(x))
    const [width, height] = two.split('x').map((x: string) => Number(x))

    claims[num] = true
    for (let x = left; x < left + width; x++) {
      for (let y = top; y < top + height; y++) {
        const key = `${x},${y}`
        const isKeyIn = R.has(key)
        if (isKeyIn(grid)) {
          claims[grid[key]] = false
          claims[num] = false
        }
        grid[`${x},${y}`] = num
      }
    }
  }
  const keyValuePairs = R.toPairs(claims)
  const isValidClaim = (kv: [string, boolean]) => kv[1] === true
  const validClaims = R.filter(isValidClaim)(keyValuePairs)
  // Object.entries is not available if we target ES5
  // const validClaims = Object.entries(claims).filter(isValidClaim)
  const result = validClaims[0][0].split('#')[1]
  console.timeEnd('Solution')
  return result
}

export const solve = () => {
  const day = '03'
  console.log(`--- Day ${day} (Part B) ---`)
  const input = readInput(day, 'input')
  const result = solveEx(input)
  console.log(result + '\n')
}
