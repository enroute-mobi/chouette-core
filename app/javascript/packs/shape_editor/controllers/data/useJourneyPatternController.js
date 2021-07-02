import { dropRight } from 'lodash'
import useSWR from 'swr'
import GeoJSON from 'ol/format/GeoJSON'

import { simplifyGeoJSON, wktOptions } from '../../shape.helpers'
import store from '../../shape.store'

const baseURL = (() => {
  const parts = window.location.pathname.split('/')
  return dropRight(parts, 2).join('/')
})()

// Custom hook which responsability is to fetch a new GeoJSON when the journeyPatternId change
export default function useJourneyPatternController() {
  // Event handlers
  const onSuccess = data => {
    const features = new GeoJSON().readFeatures(
      simplifyGeoJSON(data),
      wktOptions
    )

    store.setAttributes({ features })
  }
  
  return useSWR(`${baseURL}.geojson`, { onSuccess })
}