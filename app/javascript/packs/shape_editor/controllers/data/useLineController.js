import { useContext } from 'react'
import { tap } from 'lodash'
import useSWR from 'swr'

import GeoJSON from 'ol/format/GeoJSON'

import { ShapeContext } from '../../shape.context'
import { simplifyGeoJSON } from '../../shape.helpers'
import { getSortedCoordinates, getSource } from '../../shape.selectors'

// Custom hook which responsability is to fetch a new LineString GeoJSON object based on state coordinates when shouldUpdateLine is set to true
export default function useLineController(
  state,
  { setAttributes, setLine }
) {
  const { baseURL, lineId, wktOptions } = useContext(ShapeContext)

  // Fetcher
  const fetcher = async url =>
    fetch(url, {
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').attributes.content.value
      },
      body: JSON.stringify({ coordinates: getSortedCoordinates(state) })
    })
    .then(res => res.json())
  
  // Event handlers
  const onSuccess = data => {
    setAttributes({ shouldUpdateLine: false })

    const lineFeature = new GeoJSON().readFeature(
      simplifyGeoJSON(data),
      wktOptions
    )
    
    lineFeature.setId(lineId)

    tap(getSource(state), source => {
      source.removeFeature(
        source.getFeatureById(lineId)
      )

      source.addFeature(lineFeature)
    })

    setLine(lineFeature)
  }

  return useSWR(
    () => state.shouldUpdateLine ? `${baseURL}/shape_editor/update_line` : null,
    fetcher,
    { onSuccess }
  )
}