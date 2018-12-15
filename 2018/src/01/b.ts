import { readInput } from '../utils'

interface IAcc {
  [propName: string]: number
}

const solveEx = (input: string[]): string => {
  console.time('Solution')
  let result = ''
  const acc: IAcc = { '0': 1 }
  let i = 0
  let sum = 0
  const inputStr = input.join(' ')
  const re: RegExp = /(\+[0-9]+|\-[0-9]+)/g
  const arr = inputStr.match(re)
  if (arr) {
    const digits = arr.map((s: string) => parseInt(s, 10))
    while (true) {
      const d = digits[i]
      sum = sum + d
      const k = `${sum}`
      if (acc[k] === 1) {
        result = `${parseInt(k, 10)}`
        break
      } else {
        acc[k] = 1
      }
      i = i === digits.length - 1 ? 0 : i + 1
    }
  }
  console.timeEnd('Solution')
  return result
}

export const solve = () => {
  const day = '01'
  console.log(`--- Day ${day} (Part B) ---`)
  const input = readInput(day, 'input')

  const result = solveEx(input)
  console.log(result + '\n')
}
