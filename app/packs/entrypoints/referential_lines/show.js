import { Path } from 'path-parser'
import GeoJSONMap from '../../src/components/GeoJSONMap'
import { setLineStyle } from '../../src/helpers/open_layers/styles'

const path = new Path('/referentials/:referentialId/lines/:id')
const { referentialId, id } = path.partialTest(location.pathname)

GeoJSONMap.init(
  [`${path.build({ referentialId, id })}/routes.geojson`],
  'routes_map',
  setLineStyle
)
