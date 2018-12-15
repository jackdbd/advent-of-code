import { readFileSync } from 'fs'
import * as path from 'path'

/**
 * Get the puzzle input for the specified day.
 * @param day The day of the Advent of Code puzzle (e.g. '01')
 * @param fileBaseName The base name of a puzzle input.
 */
export const readInput = (day: string, fileBaseName: string): string[] => {
  // move one level up becaus __dirname could be either src/ or dist/
  const inputPath: string = path.join(
    __dirname,
    '..',
    'src',
    day,
    'inputs',
    `${fileBaseName}.txt`
  )
  return readFileSync(inputPath, 'utf-8')
    .trim()
    .split('\n')
}
