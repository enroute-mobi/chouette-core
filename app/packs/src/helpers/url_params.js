export const getId = type => {
  const match = window.location.pathname.match(new RegExp(`${type}\/([0-9]+)`))

  return match ? match[1] : null
}

export const getWorkgroupId = () => getId('workgroups')
export const getWorkbenchId = () => getId('workbenches')
export const getReferentialId = () => getId('referentials')
export const getLineId = () => getId('lines')
export const getRouteId = () => getId('routes')
