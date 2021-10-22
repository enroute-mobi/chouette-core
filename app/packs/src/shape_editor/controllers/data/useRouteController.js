import { useEffect } from 'react'

import useSWR from 'swr'
import { useParams } from 'react-router-dom'

import eventEmitter, { events } from '../../shape.event-emitter'
import { mapFormat } from '../../shape.helpers'
import store from '../../shape.store'

// Custom hook which responsability is to fetch a new GeoJSON when the journeyPatternId change
export default function useRouteController(_isEdit) {
  // Route params
  const { referentialId, lineId, routeId } = useParams()

  // Event handlers
  const onSuccess = data => {
    const routeFeatures = mapFormat.readFeatures(data)

    store.receivedRouteFeatures({ routeFeatures })

    eventEmitter.emit(events.receivedRouteFeatures, routeFeatures)
  }

  const { mutate: fetchRoute } = useSWR(
    `/referentials/${referentialId}/lines/${lineId}/routes/${routeId}.geojson`,
    url => fetch(url).then(res => res.text()),
    { onSuccess, revalidateOnMount: false })

  useEffect(() => { eventEmitter.on('map:init', fetchRoute) }, [])
}
