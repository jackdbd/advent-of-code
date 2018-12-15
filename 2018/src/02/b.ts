import * as R from 'ramda'
import { readInput } from '../utils'

interface IDict {
  [propName: string]: string
}

const solveEx = (input: string[]): string => {
  console.time('Solution')
  let commonLetters: string = ''
  /**
   * The boxes will have IDs which differ by exactly ONE character at the SAME
   * POSITION in both strings.
   */
  for (const i of R.range(0, input[0].length)) {
    // Gather all boxes IDs with exactly ONE character removed
    const removed = input.slice().map((boxId: string) => {
      const exploded = boxId.split('')
      // Remove the character at i-th position
      exploded.splice(i, 1)
      return exploded.join('')
    })

    /**
     * Use an object to check whether we encountered this id or not.
     * Note: a Set would be a more appropriate data structure, but it's not
     * available because our compilation target is ES5 (see tsconfig.json).
     */
    const d: IDict = {}

    // idRemoved: a box ID with ONE character removed
    for (const idRemoved of removed) {
      const hasId = R.has(idRemoved)
      if (hasId(d)) {
        commonLetters = idRemoved
        break
      } else {
        d[idRemoved] = idRemoved
      }
    }
  }
  console.timeEnd('Solution')
  return commonLetters
}

export const solve = () => {
  const day = '02'
  console.log(`--- Day ${day} (Part B) ---`)
  const input = readInput(day, 'input')
  const result = solveEx(input)
  console.log(result + '\n')
}
