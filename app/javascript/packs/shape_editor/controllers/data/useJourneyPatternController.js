import useSWR from 'swr'
import { useParams  } from 'react-router-dom'
import GeoJSON from 'ol/format/GeoJSON'

import { getLine, simplifyGeoJSON, wktOptions } from '../../shape.helpers'
import store from '../../shape.store'

// Custom hook which responsability is to fetch a new GeoJSON when the journeyPatternId change
export default function useJourneyPatternController(baseURL) {
  // Route params
  const { action } = useParams()

  // Event handlers
  const onSuccess = data => {
    const features = new GeoJSON().readFeatures(
      simplifyGeoJSON(data),
      wktOptions
    )
  
    store.setAttributes({
      features,
      name: getLine(features).get('name')
    })
  }
  
  return useSWR(`${baseURL}/shapes/${action}`, { onSuccess })
}