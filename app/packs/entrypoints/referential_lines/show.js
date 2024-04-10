import { Path } from 'path-parser'
import GeoJSONMap from '../../src/components/GeoJSONMap'
import { setLineStyle } from '../../src/helpers/open_layers/styles'

const path = new Path('/workbenches/:workbenchId/referentials/:referentialId/lines/:id')
const { workbenchId, referentialId, id } = path.partialTest(location.pathname)

GeoJSONMap.init(
  [`${path.build({ workbenchId, referentialId, id })}/routes.geojson`],
  'routes_map',
  setLineStyle
)
