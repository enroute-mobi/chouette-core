
import { Path } from 'path-parser'
import GeoJSONMap from '../../src/components/GeoJSONMap'

const path = new Path('/workbenches/:workbenchId/stop_area_referential/entrances/:id')
const params = path.partialTest(location.pathname)

GeoJSONMap.init(
  `${path.build(params)}.geojson`,
  'entrance_map'
)
