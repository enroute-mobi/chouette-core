import '../../helpers/polyfills'

import clone from '../../helpers/clone'
import RoutesMap from '../../helpers/connection_links_map'

console.log('test')
let connection_link = clone(window, "connection_link", true)
connection_link = JSON.parse(decodeURIComponent(connection_link))
console.log(connection_link)

new RoutesMap('routes_map').prepare().then(function(map){
  map.addConnectionLink(connection_link)
  // map.addRoutesLabels()
  map.fitZoom()
})
// let routes = clone(window, "routes", true)
// routes = JSON.parse(decodeURIComponent(routes))
//
// new RoutesMap('routes_map').prepare().then(function(map){
//   map.addRoutes(routes)
//   map.addRoutesLabels()
//   map.fitZoom()
// })
