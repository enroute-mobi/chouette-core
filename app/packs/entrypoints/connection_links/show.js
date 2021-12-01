import { Path } from 'path-parser'
import GeoJSONMap from '../../src/components/GeoJSONMap'

import { setConnectionLinkStyle } from '../../src/helpers/open_layers/styles'

const path = new Path('/workbenches/:workbenchId/stop_area_referential/connection_links/:id')
const params = path.partialTest(location.pathname)

GeoJSONMap.init(
  [`${path.build(params)}.geojson`],
  'connection_link_map',
  setConnectionLinkStyle
)

