import '../../helpers/polyfills'

import clone from '../../helpers/clone'
import RoutesMap from '../../helpers/maps/RoutesMap'

let route = clone(window, "route", true)
route = JSON.parse(decodeURIComponent(route))

new RoutesMap('route_map').prepare().then(generator => {
  const map = generator.next().value
  map.addRoute(route)
  generator.next()
})