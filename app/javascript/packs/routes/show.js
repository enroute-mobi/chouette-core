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
  const { origin, pathname } = window.location
  const url = `${origin}${pathname}.json`
  fetch(url)
  .then(res => {
    const json = res.json()
    json.then(mapGenerator)
  })
  .catch(e => console.error(e))
}

document.addEventListener(
  'mapSourceLoaded',
  fetchRoute(generateMap)
)
