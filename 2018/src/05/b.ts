import * as R from 'ramda'
import { readInput } from '../utils'
import { solveEx as react } from './a'

const alphabetLower: string[] = 'abcdefghijklmnopqrstuvwxyz'.split('')

const pairUpperLower = (lowerChar: string): string[] => {
  return [R.toUpper(lowerChar), lowerChar]
}

type Pipe = (x0: string) => string
const createPipe = ([upperChar, lowerChar]: string[]): Pipe => {
  const rmUpper = R.replace(RegExp(upperChar, 'g'), '')
  const rmLower = R.replace(RegExp(lowerChar, 'g'), '')
  return R.pipe(
    rmUpper,
    rmLower
  )
}

const computeLength = (polymer: string): number => react([polymer])

const solveEx = (input: string[]): number => {
  const originalPolymer = input[0]
  const pairs = R.map(pairUpperLower)(alphabetLower)
  const pipes = R.map(createPipe)(pairs)
  const simplifyPolymer = (f: Pipe): string => f(originalPolymer)
  const simplifiedPolymers = R.map(simplifyPolymer)(pipes)
  const lengths = R.map(computeLength)(simplifiedPolymers)
  const result = R.apply(Math.min, lengths)
  return result
}

export const solve = () => {
  const day = '05'
  console.log(`--- Day ${day} (Part B) ---`)
  const input = readInput(day, 'input')
  console.time('Solution')
  const result = solveEx(input)
  console.timeEnd('Solution')
  console.log(result + '\n')
}
