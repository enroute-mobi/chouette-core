import { Fill, Stroke, Circle, Style } from 'ol/style'
import GeometryType from 'ol/geom/GeometryType'

// Return style for Route Map
function routeMapStyle(props) {

  var white = [255, 255, 255, 1]
  var black = [0, 0, 0, 1]
  var width = 2

  var strokeColor = props.strokeColor || black
  var fillColor = props.fillColor || white

  var fill = new Fill({
   color: fillColor
  })

  var stroke = new Stroke({
   color: strokeColor,
   width: width
  })

  var styles = [
   new Style({
     image: new Circle({
       fill: fill,
       stroke: stroke,
       radius: 5
     }),
     fill: fill,
     stroke: stroke
   })
  ]

  return styles
}

export default routeMapStyle
