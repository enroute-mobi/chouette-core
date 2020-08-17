import '../../helpers/polyfills'
import clone from '../../helpers/clone'
import ShapesKml from '../../helpers/shapes_kml'

function fetchApiURL(){
  return window.location.origin + window.kml_url
}

new ShapesKml('route_map', fetchApiURL()).prepare()
