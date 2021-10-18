import '../../src/helpers/polyfills'

import clone from '../../src/helpers/clone'
import ConnectionLinksMap from '../../src/helpers/connection_links_map'

let connection_link = clone(window, "connection_link", true)
connection_link = JSON.parse(decodeURIComponent(connection_link))

let map_pin_orange = clone(window, "map_pin_orange", true)
map_pin_orange = decodeURIComponent(map_pin_orange)

let map_pin_blue = clone(window, "map_pin_blue", true)
map_pin_blue = decodeURIComponent(map_pin_blue)

new ConnectionLinksMap('connection_link_map').prepare().then(function(map){
  map.addMarker([map_pin_orange, map_pin_blue])
  map.addConnectionLink(connection_link)
  map.fitZoom()
})
