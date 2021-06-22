import { useContext } from 'react'
import useSWR from 'swr'
import { uniqueId } from 'lodash'
import GeoJSON from 'ol/format/GeoJSON'

import { ShapeContext } from '../../shape.context'
import { actions, helpers } from '../../shape.reducer'
import { usePrevious } from '../../../../helpers/hooks'

// Custom hook which responsability is to fetch a new GeoJSON when the journeyPatternId change
export default function useJourneyPatternGeoJSON({ journeyPatternId }, dispatch) {
  const { baseURL, lineId, wktOptions } = useContext(ShapeContext)
  const previousJourneyPatternId = usePrevious(journeyPatternId)

  // Helpers
  const journeyPatternIdDidChange = previousJourneyPatternId != journeyPatternId

  // Event handlers
  const onSuccess = data => {
    const features = new GeoJSON().readFeatures(
      helpers.simplifyGeoJSON(data),
      wktOptions
    )
    const line = features.find(f => f.getGeometry().getType() == 'LineString')
    const waypoints = features.filter(f => f.getGeometry().getType() == 'Point')

    line.setId(lineId)

    waypoints.forEach(w => {
      w.setId(uniqueId('waypoint_'))
      w.set('type', 'waypoint')
    })

    dispatch(actions.setLine(line))
    dispatch(actions.setWaypoints(waypoints))
    dispatch(actions.setAttributes({ features }))
  }
  
  return useSWR(
    () => journeyPatternIdDidChange ? `${baseURL}/journey_patterns/${journeyPatternId}.geojson` : null,
    { onSuccess }
  )
}