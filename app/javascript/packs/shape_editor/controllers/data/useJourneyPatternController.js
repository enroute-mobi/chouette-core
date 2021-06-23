import { useContext } from 'react'
import useSWR from 'swr'
import { uniqueId } from 'lodash'
import GeoJSON from 'ol/format/GeoJSON'

import { ShapeContext } from '../../shape.context'
import { simplifyGeoJSON } from '../../shape.helpers'
import { usePrevious } from '../../../../helpers/hooks'

// Custom hook which responsability is to fetch a new GeoJSON when the journeyPatternId change
export default function useJourneyPatternController(
  { journeyPatternId },
  { setAttributes, setLine, setWaypoints }
) {
  const { baseURL, lineId, wktOptions } = useContext(ShapeContext)
  const previousJourneyPatternId = usePrevious(journeyPatternId)

  // Helpers
  const journeyPatternIdDidChange = previousJourneyPatternId != journeyPatternId

  // Event handlers
  const onSuccess = data => {
    const features = new GeoJSON().readFeatures(
      simplifyGeoJSON(data),
      wktOptions
    )
    const line = features.find(f => f.getGeometry().getType() == 'LineString')
    const waypoints = features.filter(f => f.getGeometry().getType() == 'Point')

    line.setId(lineId)

    waypoints.forEach(w => {
      w.setId(uniqueId('waypoint_'))
      w.set('type', 'waypoint')
    })

    setLine(line)
    setWaypoints(waypoints)
    setAttributes({ features })
  }
  
  return useSWR(
    () => journeyPatternIdDidChange ? `${baseURL}/journey_patterns/${journeyPatternId}.geojson` : null,
    { onSuccess }
  )
}