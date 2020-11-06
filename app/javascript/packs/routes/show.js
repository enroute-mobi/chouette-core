import '../../helpers/polyfills'

import clone from '../../helpers/clone'
import RoutesMap from '../../helpers/routes_map'

let route = clone(window, "route", true)
route = JSON.parse(decodeURIComponent(route))

new RoutesMap('route_map').prepare().then(function(map){
  map.addRoute(route)
  map.fitZoom()
})
