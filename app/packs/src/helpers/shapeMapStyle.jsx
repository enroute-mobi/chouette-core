import { Fill, Stroke, Circle, Style } from 'ol/style'

// Return style for Route Map
const shapeMapStyle = (props={}) => {

  const white = [255, 255, 255, 1]
  const red = [255, 0, 0, 1]
  const width = 2

  const strokeColor = props.strokeColor || red
  const fillColor = props.fillColor || white

  const fill = new Fill({ color: fillColor })

  const stroke = new Stroke({ color: strokeColor, width })

  return new Style({
    image: new Circle({
      fill,
      stroke,
      radius: 5
    }),
    fill,
    stroke
  })
}

export default shapeMapStyle
