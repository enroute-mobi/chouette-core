import { Path } from 'path-parser'
import GeoJSONMap from '../../src/components/GeoJSONMap'

import { setConnectionLinkStyle } from '../../src/helpers/open_layers/styles'

const path = new Path('/workbenches/:workbenchId/stop_area_referential/stop_areas/:id')
const params = path.partialTest(location.pathname)

const baseURL = path.build(params)
const stopAreaURL = `${baseURL}.geojson`
const connectionLinksURL = `${baseURL}/fetch_connection_links.geojson`

GeoJSONMap.init(
  [stopAreaURL, connectionLinksURL],
  'connection_link_map',
  ([_stop_area, ...connectionLinks]) => {
    setConnectionLinkStyle(connectionLinks)
  }
)

