import { useEffect } from 'react'

import useSWR, { mutate } from 'swr'
import { useParams } from 'react-router-dom'
import GeoJSON from 'ol/format/GeoJSON'

import eventEmitter from '../../shape.event-emitter'
import store from '../../shape.store'

const wktOptions = {
  dataProjection: 'EPSG:4326',
  featureProjection: 'EPSG:3857'
}

// Custom hook which responsability is to fetch a new GeoJSON when the journeyPatternId change
export default function useRouteController(_isEdit) {
  // Route params
  const { referentialId, lineId, routeId } = useParams()
  const url = `/referentials/${referentialId}/lines/${lineId}/routes/${routeId}.geojson`

  useEffect(() => {
    eventEmitter.on('map:init', () => mutate(url))
  }, [])

  // Event handlers
  const onSuccess = data => {    
    store.getState(({ routeFeatures }) => {
      routeFeatures.extend(
        new GeoJSON().readFeatures(data, wktOptions)
      )

      routeFeatures.dispatchEvent('receiveFeatures')
    })
  }
  
  return useSWR(
    url,
    url => fetch(url).then(res => res.text()),
    { onSuccess, revalidateOnMount: false })
}