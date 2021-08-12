import '../../src/helpers/polyfills'

import clone from '../../src/helpers/clone'
import RoutesMap from '../../src/helpers/routes_map'

let routes = clone(window, "routes", true)
routes = JSON.parse(decodeURIComponent(routes))

new RoutesMap('routes_map').prepare().then(function(map){
  map.addRoutes(routes)
  map.addRoutesLabels()
  map.fitZoom()
})
