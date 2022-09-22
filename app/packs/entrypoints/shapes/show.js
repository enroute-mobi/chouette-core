import { Path } from 'path-parser'
import GeoJSONMap from '../../src/components/GeoJSONMap'
import shapeMapStyle from '../../src/helpers/shapeMapStyle'

const path = new Path('/workbenches/:workbenchId/shape_referential/shapes/:id')
const { workbenchId, id } = path.partialTest(location.pathname)

GeoJSONMap.init(
  [`${path.build({ workbenchId, id })}.geojson`],
  'route_map',
  (lineStrings) => {
		lineStrings.forEach (lineString => {
			lineString.setStyle(shapeMapStyle())
		})
  }
)
