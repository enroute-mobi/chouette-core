import { Path } from 'path-parser'
import TravelTimeCalculator from '../../src/connection_links/travel_time_calculator'

const init = async () => {
	const path = new Path('/workbenches/:workbenchId/stop_area_referential/connection_links')
	const { workbenchId } = path.partialTest(location.pathname)

	const res = await fetch(`${path.build({ workbenchId })}/get_connection_speeds`)
	const { connectionSpeed } = await res.json()

	new TravelTimeCalculator(connectionSpeed)
}

init()
