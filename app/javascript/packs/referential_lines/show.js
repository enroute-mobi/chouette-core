import '../../helpers/polyfills'

import RoutesMap from '../../helpers/maps/RoutesMap'

const updateeMap = routes => handler => {
  const map = handler.next().value
  map.addRoutes(routes)
  map.addLabels('routes')
  handler.next()
}

const generateMap = routes => {
  new RoutesMap('routes_map').prepare()
    .then(updateeMap(routes))
}

const fetchRoutes = mapGenerator => {
  fetch(`${window.location.href}.json`).then(res => {
    const json = res.json()
    json.then(mapGenerator)
  })
}

$(document).on('mapSourceLoaded', () => fetchRoutes(generateMap))