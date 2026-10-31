// Shapes API data for charts. Charts plot numbers, so money strings become
// numbers here, for drawing only; the figures shown as text stay exact.
export function donutData(groups) {
  return groups.filter((group) => group.annual_cost !== null).map((group) => ({ name: group.name, value: Number(group.annual_cost) }))
}

export function costTrendData(points) {
  return points.map((point) => ({ month: point.month, value: point.monthly_cost === null ? null : Number(point.monthly_cost) }))
}

export function movementData(points) {
  return points.flatMap((point) => [
    { month: point.month, type: 'Joiners', count: point.joiners },
    { month: point.month, type: 'Leavers', count: point.leavers },
  ])
}

export function timelineData(revisions) {
  return [...revisions]
    .sort((a, b) => a.effective_on.localeCompare(b.effective_on))
    .map((revision) => ({ date: revision.effective_on, value: Number(revision.amount), currency: revision.currency_code }))
}
