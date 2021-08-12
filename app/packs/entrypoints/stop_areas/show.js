import '../../src/helpers/polyfills'

import clone from '../../src/helpers/clone'
import ConnectionLinksMap from '../../src/helpers/connection_links_map'

// let connected_stops = clone(window, "connected_stops", true)
// connected_stops = JSON.parse(decodeURIComponent(connected_stops))
// console.log(connected_stops)

let stop_areas = clone(window, "stop_areas", true)
stop_areas = JSON.parse(decodeURIComponent(stop_areas))
console.log(stop_areas)

let map_pin_orange = clone(window, "map_pin_orange", true)
map_pin_orange = decodeURIComponent(map_pin_orange)

let map_pin_blue = clone(window, "map_pin_blue", true)
map_pin_blue = decodeURIComponent(map_pin_blue)

new ConnectionLinksMap('connection_link_map').prepare().then(function(map){
  map.addMarker([map_pin_orange, map_pin_blue])
  map.addStops(stop_areas)
  map.fitZoom()
})
