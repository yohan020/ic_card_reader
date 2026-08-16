/**
 * @param {string | null} value
 * @param {number} minimum
 * @param {number} maximum
 * @param {number} fallback
 * @returns {number}
 */
export function clampInteger(value, minimum, maximum, fallback) {
  if (value === null || value.trim() === '') return fallback
  const parsed = Number(value)
  return Number.isInteger(parsed)
    ? Math.min(maximum, Math.max(minimum, parsed))
    : fallback
}
