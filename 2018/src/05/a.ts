import { readInput } from '../utils'

const isLowerCaseUpperCasePair = (x: number) => x === 32

export const solveEx = (input: string[]): number => {
  let polymer = input[0]
  for (let i = 0; i < polymer.length - 1; i++) {
    const asciiPairDiff = Math.abs(
      polymer.charCodeAt(i) - polymer.charCodeAt(i + 1)
    )
    if (isLowerCaseUpperCasePair(asciiPairDiff)) {
      polymer = `${polymer.slice(0, i)}${polymer.slice(i + 2)}`
      i -= 2
    }
  }
  return polymer.length
}

export const solve = () => {
  const day = '05'
  console.log(`--- Day ${day} (Part A) ---`)
  const input = readInput(day, 'input')
  console.time('Solution')
  const result = solveEx(input)
  console.timeEnd('Solution')
  console.log(result + '\n')
}
