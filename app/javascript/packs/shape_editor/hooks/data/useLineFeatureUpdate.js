import { useContext } from 'react'
import useSWR from 'swr'

import GeoJSON from 'ol/format/GeoJSON'

import { ShapeContext } from '../../shape.context'
import { actions, helpers, selectors } from '../../shape.reducer'

// Custom hook which responsability is to fetch a new LineString GeoJSON object based on state coordinates when shouldUpdateLine is set to true
export default function useLineFeatureUpdate(state, dispatch) {
  const { baseURL, lineId, wktOptions } = useContext(ShapeContext)

  const coordinates = selectors.getSortedCoordinates(state)

  // Fetcher
  const fetcher = async url =>
    fetch(url, {
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').attributes.content.value
      },
      body: JSON.stringify({ coordinates })
    })
    .then(res => res.json())
  

  // Event handlers
  const onSuccess = data => {
    dispatch(actions.setAttributes({ shouldUpdateLine: false }))

    const lineFeature = new GeoJSON().readFeature(
      helpers.simplifyGeoJSON(data),
      wktOptions
    )
    const source = state.featuresLayer.getSource()

    lineFeature.setId(lineId)

    source.removeFeature(
      source.getFeatureById(lineId)
    )

    source.addFeature(lineFeature)

    dispatch(actions.setLine(lineFeature))
  }

  return useSWR(
    () => state.shouldUpdateLine ? `${baseURL}/shape_editor/update_line` : null,
    fetcher,
    { onSuccess }
  )
}