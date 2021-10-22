import { useEffect } from 'react'
import useSWR from 'swr'

import { submitFetcher } from '../../shape.helpers'
import { getWaypointsCoords } from '../../shape.selectors'
import store from '../../shape.store'
import eventEmitter, { events } from '../../shape.event-emitter'

// Custom hook which responsability is to fetch a new LineString GeoJSON object based on state coordinates when shouldUpdateLine is set to true
export default function useLineController(_isEdit, baseURL) {
  const url = `${baseURL}/shapes/update_line`

  // Event handlers
  const onSuccess = geometry => {
    store.updateGeometry({ geometry })

    eventEmitter.emit(events.lineUpdated)
  }

  const { mutate: updateLine } = useSWR(
    url,
    async url => {
      const state = await store.getStateAsync()
      const payload = { coordinates: getWaypointsCoords(state) }

      return submitFetcher(url, 'PUT', payload)
    },
    { onSuccess, revalidateOnMount: false }
  )

  useEffect(() => {
    eventEmitter.on(events.waypointUpdated, updateLine)
  }, [])
}
