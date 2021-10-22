
import { Path } from 'path-parser'
import GeoJSONMap from '../../src/components/GeoJSONMap'

const path = new Path('/referentials/:referentialId/lines/:lineId/routes/:id')
const { referentialId, lineId, id } = path.partialTest(location.pathname)

GeoJSONMap.init(
  `${path.build({ referentialId, lineId, id })}.geojson`,
  'route_map'
)
