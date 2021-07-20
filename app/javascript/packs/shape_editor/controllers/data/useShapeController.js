import { useEffect, useState } from 'react'
import { useParams  } from 'react-router-dom'
import useSWR from 'swr'

import GeoJSON from 'ol/format/GeoJSON'

import { getLine, simplifyGeoJSON, submitFetcher, wktOptions } from '../../shape.helpers'
import { getSubmitPayload } from '../../shape.selectors'
import store from '../../shape.store'
import eventEmitter from '../../shape.event-emitter'

// Custom hook which responsability is to fetch / submit a shape object
export default function useShapeController(isEdit, baseURL) {
  const [shouldFetch, setShouldFetch] = useState(false)
  const [shouldSubmit, setShouldSubmit] = useState(false)

  // Route params
  const { action } = useParams()

  const onFetchSuccess = data => {
    setShouldFetch(false)

    const features = new GeoJSON().readFeatures(simplifyGeoJSON(data), wktOptions(isEdit))
  
    store.setAttributes({ features, name: getLine(features).get('name') })
  }

  const onSubmitSuccess = () => {}

  const onSubmitError = errors => {
    errors.forEach(text => {
      window.Spruce.stores.flash.add({ type: 'error', text })
    })
  }

  const params = new Params(isEdit, baseURL, action)
  const fetchParams = params.fetch(shouldFetch, onFetchSuccess)
  const submitParams = params.submit(shouldSubmit, onSubmitSuccess, onSubmitError)

  // Fetch Shape
  useSWR(...fetchParams)
  
  // Submit Shape
  useSWR(...submitParams)

  useEffect(() => {
    eventEmitter.on('shape:submit', () => setShouldSubmit(true))
    eventEmitter.on('map:init', () => setShouldFetch(true))
  }, [])
}

class Params {
  constructor(isEdit, baseURL, action) {
    this.isEdit = isEdit
    this.baseURL = baseURL
    this.action = action
  }

  fetch(shouldFetch, onSuccess) {
    return [
      shouldFetch ? `${this.baseURL}/shapes/${this.action}` : null,
      { onSuccess }
    ]
  }

  submit(shouldSubmit, onSuccess, onError) {
    return [
      shouldSubmit ? `${this.baseURL}/shapes` : null,
      async url => {
        const state = await store.getStateAsync()

        return submitFetcher(url, this.isEdit, getSubmitPayload(state))
      },
      { onSuccess, onError }
    ]
  }
}
