import '../../helpers/polyfills'

import clone from '../../helpers/clone'
import RoutesMap from '../../helpers/maps/RoutesMap'

let routes = clone(window, "routes", true)
routes = JSON.parse(decodeURIComponent(routes))

new RoutesMap('routes_map').prepare().then(generator => {
  const map = generator.next().value
  map.addRoutes(routes)
  map.addLabels('routes')
  generator.next()
})
