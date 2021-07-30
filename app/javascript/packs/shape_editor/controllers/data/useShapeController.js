import { useEffect } from 'react'
import { useParams  } from 'react-router-dom'
import useSWR, { mutate } from 'swr'

import GeoJSON from 'ol/format/GeoJSON'

import { simplifyGeoJSON, submitFetcher, wktOptions } from '../../shape.helpers'
import { getSubmitPayload } from '../../shape.selectors'
import store from '../../shape.store'
import eventEmitter from '../../shape.event-emitter'

// Custom hook which responsability is to fetch / submit a shape object
export default function useShapeController(isEdit, baseURL) {
  // Route params
  const { action } = useParams()

  const fetchURL = `${baseURL}/shapes/${action}`
  const submitURL = `${baseURL}/shapes`

  // Fetch Shape
  useSWR(...Params.fetch(fetchURL, isEdit))
  
  // Submit Shape
  useSWR(...Params.submit(submitURL, isEdit))

  useEffect(() => {
    eventEmitter.on('shape:submit', () => mutate(submitURL))
    eventEmitter.on('map:init', () => mutate(fetchURL))
  }, [])
}
class Params {
  static fetch = (url, isEdit) => [
    url,
    {
      onSuccess(data) {
        store.getState(({ shapeFeatures }) => {
          const fetchedFeatures = new GeoJSON().readFeatures(simplifyGeoJSON(data), wktOptions(isEdit))
          
          shapeFeatures.extend(fetchedFeatures)

          store.setAttributes({ mapWrapperFeatures: fetchedFeatures, shapeFeatures, name: shapeFeatures.item(0).get('name') })
          shapeFeatures.dispatchEvent('receiveFeatures')
        })
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
        errors.forEach(text => {
          window.Spruce.stores.flash.add({ type: 'error', text })
        })
      },
      revalidateOnMount: false
    }
  ]
}
