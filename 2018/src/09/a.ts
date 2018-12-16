import * as R from 'ramda'
import { readInput } from '../utils'

const getPlayersAndPoints = (words: string[]): number[] => {
  const radix = 10
  return [parseInt(words[0], radix), parseInt(words[6], radix)]
}

const defineGame = (input: string): number[] => {
  const words = R.split(' ')(input)
  const [numPlayers, lastMarblePoints] = getPlayersAndPoints(words)
  return [numPlayers, lastMarblePoints]
}

const isMultipleOf23 = (n: number) => n !== 0 && R.modulo(n, 23) === 0

const cwNextIndex = (arr: number[], i: number): number => {
  const nextIndex = i + 2 <= arr.length ? i + 2 : 1
  return nextIndex
}

const ccwNextIndex = (arr: number[], i: number): number => {
  const nextIndex = i - 7 >= 0 ? i - 7 : arr.length + (i - 7)
  return nextIndex
}

const isGameFinished = (
  marbles: number[],
  lastMarblePoints: number
): boolean => {
  const causesTheGameToEnd = (x: number): boolean => x === lastMarblePoints
  return R.any(causesTheGameToEnd, marbles)
}

interface ITurn {
  cm: number
  icm: number
  marbles: number[]
  marblesKept: number[]
}

interface IPlayer {
  marblesKept: number[]
  score: number
}

interface IPlayersMap {
  [propName: string]: IPlayer
}

const playTurn = (marbles: number[], cm: number, icm: number): ITurn => {
  cm++
  let marblesKept: number[] = []
  if (isMultipleOf23(cm)) {
    icm = ccwNextIndex(marbles, icm)
    marblesKept = [cm, marbles[icm]]
    const iRemove = marbles.indexOf(marbles[icm])
    marbles.splice(iRemove, 1) // remove this marble, don't insert cm
  } else {
    icm = cwNextIndex(marbles, icm)
    marbles.splice(icm, 0, cm) // insert current marble
    marblesKept = []
  }
  const turn: ITurn = {
    cm,
    icm,
    marbles,
    marblesKept,
  }
  return turn
}

export const solveEx = (input: string[]): number => {
  const [numPlayers, lastMarblePoints] = defineGame(input[0])
  console.log(`This game played by ${numPlayers} players.`)
  console.log(
    `This game ends when the marble that is worth ${lastMarblePoints} points is USED`
  )
  const reducer = (acc: IPlayersMap, cv: number): IPlayersMap => {
    const marblesKept: number[] = []
    const score: number = 0
    const player = `${cv}`
    const obj = { [player]: { marblesKept, score } }
    acc = { ...acc, ...obj }
    return acc
  }
  const playersMap: IPlayersMap = R.range(0, numPlayers).reduce(reducer, {})
  let cm = 0 // current marble
  let marbles = [cm]
  let icm = 0 // i current marble

  let iPlayer = 0
  while (true) {
    const turn = playTurn(marbles, cm, icm)
    cm = turn.cm
    icm = turn.icm
    marbles = turn.marbles
    const marblesKept = turn.marblesKept
    if (marblesKept.length) {
      playersMap[`${iPlayer}`].marblesKept.push(...marblesKept)
      playersMap[`${iPlayer}`].score =
        playersMap[`${iPlayer}`].score + marblesKept[0] + marblesKept[1]
      // console.log(`Player ${iPlayer} keeps [${marblesKept}]`)
      // console.log(
      //   `Player ${iPlayer} is now at ${playersMap[iPlayer].score} points`
      // )
    }
    if (isGameFinished(marbles, lastMarblePoints)) {
      break
    }
    iPlayer = iPlayer + 1 < R.keys(playersMap).length ? iPlayer + 1 : 0
  }
  const playerIds: any[] = R.keys(playersMap)
  const getScore = (id: string) => playersMap[id].score
  const scoresPerPlayer = R.map(getScore)(playerIds)
  const highScore = R.apply(Math.max, scoresPerPlayer)
  return highScore
}

export const solve = () => {
  const day = '09'
  console.log(`--- Day ${day} (Part A) ---`)
  const input = readInput(day, 'sample1')
  console.time('Solution')
  const result = solveEx(input)
  console.timeEnd('Solution')
  console.log(result + '\n')
}
