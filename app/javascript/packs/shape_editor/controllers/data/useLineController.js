import { pick } from 'lodash'
import useSWR from 'swr'

import GeoJSON from 'ol/format/GeoJSON'

import { useStore } from '../../../../helpers/hooks'
import { simplifyGeoJSON } from '../../shape.helpers'
import { getSortedCoordinates, getSource } from '../../shape.selectors'

const mapStateToProps = state => ({
  ...pick(state, ['baseURL', 'lineId', 'setAttributes', 'setLine', 'shouldUpdateLine', 'wktOptions']),
  source: getSource(state),
  coordinates: getSortedCoordinates(state)
})

// Custom hook which responsability is to fetch a new LineString GeoJSON object based on state coordinates when shouldUpdateLine is set to true
export default function useLineController(store) {
  // Store
  const [
    { baseURL, coordinates, lineId, setAttributes, setLine, shouldUpdateLine, source, wktOptions }
  ] = useStore(store, mapStateToProps)

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
    setAttributes({ shouldUpdateLine: false })

    const lineFeature = new GeoJSON().readFeature(
      simplifyGeoJSON(data),
      wktOptions
    )
    
    lineFeature.setId(lineId)

    source.removeFeature(
      source.getFeatureById(lineId)
    )

    source.addFeature(lineFeature)

    setLine(lineFeature)
  }

  return useSWR(
    () => shouldUpdateLine ? `${baseURL}/shape_editor/update_line` : null,
    fetcher,
    { onSuccess }
  )
}