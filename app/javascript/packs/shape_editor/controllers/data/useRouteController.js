import { useEffect, useState } from 'react'

import useSWR from 'swr'
import { useParams  } from 'react-router-dom'
import KML from 'ol/format/KML'

import eventEmitter from '../../shape.event-emitter'
import { getStaticSource } from '../../shape.selectors'
import store from '../../shape.store'

const wktOptions = {
  dataProjection: 'EPSG:4326',
  featureProjection: 'EPSG:3857'
}

// Custom hook which responsability is to fetch a new GeoJSON when the journeyPatternId change
export default function useRouteController(isEdit) {
  const [shouldFetch, setShouldFetch] = useState(false)

  // Route params
  const { referentialId, lineId, routeId } = useParams()
  const url = `/referentials/${referentialId}/lines/${lineId}/routes/${routeId}.kml`

  useEffect(() => {
    eventEmitter.on('map:init', () => setShouldFetch(true))
  }, [])

  // Event handlers
  const onSuccess = async data => {
    const features = new KML().readFeatures(data, wktOptions)

    console.log('features', features)
    
    const state = await store.getStateAsync()
    const staticSource = getStaticSource(state)

    staticSource.addFeatures(features)
  }
  
  return useSWR(
    () => shouldFetch ? url : null,
    url => fetch(url).then(res => res.text()),
    { onSuccess })
}