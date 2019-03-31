import '../../helpers/polyfills'

import RoutesMap from '../../helpers/maps/RoutesMap'

const updateeMap = route => handler => {
  const map = handler.next().value
  map.addRoute(route)
  handler.next()
}

const generateMap = route => {
  new RoutesMap('route_map').prepare()
    .then(updateeMap(route))
}

const fetchRoute = mapGenerator => {
  fetch(`${window.location.href}.json`).then(res => {
    const json = res.json()
    json.then(mapGenerator)
  })
}

$(document).on('mapSourceLoaded', () => fetchRoute(generateMap))
