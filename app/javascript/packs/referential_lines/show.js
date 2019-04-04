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
  const { origin, pathname } = window.location
  const url = `${origin}${pathname}.json`
  fetch(url)
  .then(res => {
    const json = res.json()
    json.then(mapGenerator)
  })
  .catch(e => console.error(e))
}

$(document).on('mapSourceLoaded', () => fetchRoutes(generateMap))