import { readInput } from '../utils'

const reducer = (acc: number, cv: number): number => acc + cv

const regexSolution = (input: string[]) => {
  console.time('Regex solution')
  let result = ''
  const inputStr = input.join(' ')
  const re: RegExp = /(\+[0-9]+|\-[0-9]+)/g
  const arr = inputStr.match(re)
  if (arr) {
    const digits = arr.map((s: string) => parseInt(s, 10))
    result = `${digits.reduce(reducer)}`
  }
  console.timeEnd('Regex solution')
  return result
}

const recursiveSolution = (input: string[]) => {
  console.time('Recursive solution')
  const reduceInput = (value: number, changes: string[]): number => {
    if (changes.length === 0) {
      return value
    } else {
      const change = changes.shift()
      if (change) {
        const newValue = [value, parseInt(change, 10)].reduce(reducer)
        return reduceInput(newValue, changes)
      } else {
        return 0
      }
    }
  }
  const num = reduceInput(0, input)
  const result = `${num}`
  console.timeEnd('Recursive solution')
  return result
}

export const solve = () => {
  const day = '01'
  console.log(`--- Day ${day} (Part A) ---`)
  const input = readInput(day, 'input')

  const resultRegex = regexSolution(input)
  console.log(resultRegex)

  const resultRecursive = recursiveSolution(input)
  console.log(resultRecursive + '\n')
}
