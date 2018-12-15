import * as R from 'ramda'
import { readInput } from '../utils'

const alphabet: string = 'abcdefghijklmnopqrstuvwxyz'

interface IDatum {
  couple: boolean
  triple: boolean
}

const countMatches = (str: string) => {
  const d: IDatum = { couple: false, triple: false }
  for (const i of R.range(0, alphabet.length)) {
    const ch = alphabet[i]
    let re: RegExp
    switch (ch) {
      case 'b':
        re = /b/gi
        break
      case 'c':
        re = /c/gi
        break
      case 'w':
        re = /w/gi
        break
      default:
        re = new RegExp(`${ch}`, 'gi')
    }
    const matches = str.match(re) || []
    if (matches.length >= 3) {
      d.triple = true
      continue
    }
    if (matches.length === 2) {
      d.couple = true
    }
  }
  return d
}

const solveEx = (input: string[]) => {
  console.time('Solution')
  let result = ''
  const dd = input.map(countMatches)
  const numCouples = dd.filter(d => d.couple === true).length
  const numTriples = dd.filter(d => d.triple === true).length
  result = `${numCouples * numTriples}`
  console.timeEnd('Solution')
  return result
}

export const solve = () => {
  const day = '02'
  console.log(`--- Day ${day} (Part A) ---`)
  const input = readInput(day, 'input')
  const result = solveEx(input)
  console.log(result + '\n')
}
