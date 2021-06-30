import useSWR from 'swr'
import GeoJSON from 'ol/format/GeoJSON'

import { baseURL, simplifyGeoJSON, wktOptions } from '../../shape.helpers'
import store from '../../shape.store'
import { usePrevious, useStore } from '../../../../helpers/hooks'

const mapStateToProps = state => state.journeyPatternId

// Custom hook which responsability is to fetch a new GeoJSON when the journeyPatternId change
export default function useJourneyPatternController() {
  // Store
  const journeyPatternId = useStore(store, mapStateToProps)

  const previousJourneyPatternId = usePrevious(journeyPatternId)

  // Helpers
  const journeyPatternIdDidChange = previousJourneyPatternId != journeyPatternId

  // Event handlers
  const onSuccess = data => {
    const features = new GeoJSON().readFeatures(
      simplifyGeoJSON(data),
      wktOptions
    )

    store.setAttributes({ features })
  }
  
  return useSWR(
    () => journeyPatternIdDidChange ? `${baseURL}/journey_patterns/${journeyPatternId}.geojson` : null,
    { onSuccess }
  )
}