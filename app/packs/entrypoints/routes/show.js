
import { Path } from 'path-parser'
import GeoJSONMap from '../../src/components/GeoJSONMap'
import { setLineStyle } from '../../src/helpers/open_layers/styles'

const path = new Path('/referentials/:referentialId/lines/:lineId/routes/:id')
const { referentialId, lineId, id } = path.partialTest(location.pathname)

GeoJSONMap.init(
  `${path.build({ referentialId, lineId, id })}.geojson`,
  'route_map',
  setLineStyle
)
