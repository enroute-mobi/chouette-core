import { Path } from 'path-parser'
import GeoJSONMap from '../../src/components/GeoJSONMap'

const path = new Path('/workbenches/:workbenchId/shape_referential/shapes/:id')
const { workbenchId, id } = path.partialTest(location.pathname)

GeoJSONMap.init(
  [`${path.build({ workbenchId, id })}.geojson`],
  'route_map'
)
