// Shapes API data for charts. Charts plot numbers, so money strings become
// numbers here, for drawing only; the figures shown as text stay exact.
export function donutData(groups) {
  return groups.filter((group) => group.annual_cost !== null).map((group) => ({ name: group.name, value: Number(group.annual_cost) }))
}
