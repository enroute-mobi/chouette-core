import useSWR from 'swr'
import { pick, uniqueId } from 'lodash'
import GeoJSON from 'ol/format/GeoJSON'

import { simplifyGeoJSON } from '../../shape.helpers'
import { usePrevious, useStore } from '../../../../helpers/hooks'

const mapStateToProps = state => pick(state, [
  'baseURL',
  'journeyPatternId',
  'lineId',
  'setAttributes',
  'setLine',
  'setWaypoints',
  'wktOptions'
])

// Custom hook which responsability is to fetch a new GeoJSON when the journeyPatternId change
export default function useJourneyPatternController(store) {
  const [
    { baseURL, journeyPatternId, lineId, setAttributes, setLine, setWaypoints, wktOptions },
  ] = useStore(store, mapStateToProps)

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