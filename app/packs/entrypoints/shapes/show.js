import '../../src/helpers/polyfills'
import clone from '../../src/helpers/clone'
import ShapesKml from '../../src/helpers/shapes_kml'

function fetchApiURL(){
  return window.location.origin + window.kml_url
}

new ShapesKml('route_map', fetchApiURL()).prepare()
