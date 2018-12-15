import * as R from 'ramda'
import { readInput } from '../utils'

interface IGuard {
  minutesAsleep: number
  minutes: any
}

interface IGuards {
  [key: string]: IGuard
}

const solveEx = (input: string[]): number => {
  console.time('Solution')

  // Organize chronologically
  const lines = input
    .map(
      (line: string): [string, number] => {
        const match = RegExp(/\[(.+)\]/).exec(line)
        // ensure the typescript compiler that we have a match (with !)
        const date: string = match![1]
        return [line, +new Date(date)]
      }
    )
    .sort((a: [string, number], b: [string, number]) => a[1] - b[1])
    .map(([line]: any[]) => line as string)

  const guards: IGuards = {}
  let currentGuardId: number = -1
  let sleptAt: number = -1

  for (const line of lines) {
    const match = RegExp(/.+ \d+\:(\d+)\] (.+)/).exec(line)

    if (match) {
      const minute = Number(match[1])
      const action = match[2]
      const guardMatch = RegExp(/Guard \#(\d+)/).exec(line)

      if (guardMatch) {
        currentGuardId = Number(guardMatch[1])

        if (!guards.hasOwnProperty(currentGuardId)) {
          guards[`${currentGuardId}`] = {
            minutes: {},
            minutesAsleep: 0,
          }
        }
      } else if (currentGuardId) {
        if (RegExp(/asleep/).test(action)) {
          sleptAt = minute
        } else if (sleptAt && RegExp(/wakes/).test(action)) {
          const duration = minute - sleptAt

          guards[currentGuardId].minutesAsleep += duration

          for (let m = sleptAt; m < minute; m++) {
            if (!guards[currentGuardId].minutes.hasOwnProperty(m)) {
              guards[currentGuardId].minutes[m] = 0
            }
            guards[currentGuardId].minutes[m] += 1
          }
        }
      }
    }
  }

  // Find guard who slept the most
  const [winningGuardId]: number[] = Object.keys(guards)
    .map(Number)
    .reduce(
      (winner: number[], guardId: number) => {
        const minutesAsleep: number = guards[guardId].minutesAsleep

        return minutesAsleep > winner[1] ? [guardId, minutesAsleep] : winner
      },
      [0, 0]
    )

  const findMostGuardMinute = (guardId: number): number[] => {
    const minutes = guards[guardId].minutes

    return Object.keys(minutes)
      .map(Number)
      .reduce(
        (winner: number[], minute: number) => {
          const count: number = minutes[minute]
          return count > winner[1] ? [minute, count] : winner
        },
        [0, 0]
      )
  }
  const result = winningGuardId * findMostGuardMinute(winningGuardId)[0]

  const keyValuePairs = R.toPairs(guards)

  const guardMinuteCountArr = keyValuePairs.map((kv: [string, IGuard]) => {
    const guardId = parseInt(kv[0], 10)
    const [minute, count] = findMostGuardMinute(guardId)
    return [guardId].concat([minute, count])
  })

  const mostAsleep = guardMinuteCountArr.reduce(
    (winner: number[], current: number[]) => {
      return current[2] > winner[2] ? current : winner
    },
    [0, 0, 0]
  )

  console.log(`Part B: ${mostAsleep[0] * mostAsleep[1]}`)
  console.timeEnd('Solution')
  return result
}

export const solve = () => {
  const day = '04'
  console.log(`--- Day ${day} (Part A & B) ---`)
  const input = readInput(day, 'input')
  const result = solveEx(input)
  console.log(result + '\n')
}
