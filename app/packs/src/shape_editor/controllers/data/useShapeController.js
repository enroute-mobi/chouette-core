import { useEffect } from 'react'
import { useParams } from 'react-router-dom'
import useSWR from 'swr'
import { get } from 'lodash'
import { featureCollection } from '@turf/turf'
import Collection from 'ol/Collection'

import { mapFormat, submitFetcher } from '../../shape.helpers'
import { getSubmitPayload } from '../../shape.selectors'
import store from '../../shape.store'
import eventEmitter, { events } from '../../shape.event-emitter'

// Custom hook which responsability is to fetch / submit a shape object
export default function useShapeController(isEdit, baseURL) {
  // Route params
  const { action } = useParams()

  // Fetch Shape
  const { mutate: fetchShape } = useSWR(...Params.fetch(`${baseURL}/shapes/${action}`))
  
  // Submit Shape
  const { mutate: submitShape } = useSWR(...Params.submit(`${baseURL}/shapes`, isEdit))

  useEffect(() => {
    eventEmitter.on(events.submitShapeRequest, submitShape)
    eventEmitter.on(events.initMap, fetchShape)
  }, [])
}
class Params {
  static fetch = url => [
    url,
    {
      onSuccess({ features }) {
        const geometry = features[0]
        const waypoints = new Collection(mapFormat.readFeatures(featureCollection(features.slice(1))))

        store.receivedShapeFeatures({ geometry, waypoints, name: get(geometry, ['properties', 'name']) })

        eventEmitter.emit(events.receivedShapeFeatures, geometry, waypoints)
      },
      revalidateOnMount: false
    }
  ]

  static submit = (url, isEdit) => [
    url,
    async url => {
      const state = await store.getStateAsync()

      return submitFetcher(url, isEdit, getSubmitPayload(state))
    },
    {
      onError(errors) {
        try {
          errors.forEach(text => {
            Spruce.stores.flash.add({ type: 'error', text })
          })
        } catch(e) {
          
        }
      },
      revalidateOnMount: false
    }
  ]
}
