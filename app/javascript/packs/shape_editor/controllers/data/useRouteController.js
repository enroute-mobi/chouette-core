import { useEffect } from 'react'

import useSWR from 'swr'
import { useParams } from 'react-router-dom'
import GeoJSON from 'ol/format/GeoJSON'

import eventEmitter from '../../shape.event-emitter'
import { wktOptions } from '../../shape.helpers'
import store from '../../shape.store'

// Custom hook which responsability is to fetch a new GeoJSON when the journeyPatternId change
export default function useRouteController(_isEdit) {
  // Route params
  const { referentialId, lineId, routeId } = useParams()

  // Event handlers
  const onSuccess = data => {
    const routeFeatures = new GeoJSON().readFeatures(data, wktOptions)

    store.setAttributes({ routeFeatures })

    eventEmitter.emit('route:receive-features', routeFeatures)
  }

  const { mutate: fetchRoute } = useSWR(
    `/referentials/${referentialId}/lines/${lineId}/routes/${routeId}.geojson`,
    url => fetch(url).then(res => res.text()),
    { onSuccess, revalidateOnMount: false })

  useEffect(() => { eventEmitter.on('map:init', fetchRoute) }, [])
}
