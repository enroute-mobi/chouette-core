import React from 'react'

import MapWrapper from '../../components/MapWrapper'
import shapeMapStyle from '../../helpers/shapeMapStyle'
import { useGeoJSONFeatures } from '../../helpers/hooks'


function ShapeMap({ shapeId }) {
  const features = useGeoJSONFeatures(`${window.shape_url}/${shapeId}.geojson`)

  return (
    <div className="openlayers_map">
      <MapWrapper features={features} style={shapeMapStyle({})} />
    </div>
  )
}

export default ShapeMap
