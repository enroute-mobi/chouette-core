import { Path } from 'path-parser'

import GeoJSONMap from '../../src/components/GeoJSONMap'

const path = new Path('/referentials/:referentialId/lines/:id')
const { referentialId, id } = path.partialTest(location.pathname)

GeoJSONMap.init(
  `${path.build({ referentialId, id })}/routes.geojson`,
  'routes_map'
)
