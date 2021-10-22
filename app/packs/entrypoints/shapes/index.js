import { Path } from 'path-parser'
import GeoJSONMap from '../../src/components/GeoJSONMap'

const path = new Path('/workbenches/:workbenchId/shape_referential/shapes')
const { workbenchId } = path.partialTest(location.pathname)

GeoJSONMap.init(
	`${path.build({ workbenchId })}.geojson`,
	'route_map'
)
