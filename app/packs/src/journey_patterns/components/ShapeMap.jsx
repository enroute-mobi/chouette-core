import React, { useState, useEffect } from 'react'

import KML from 'ol/format/KML'
import Feature from 'ol/Feature'
import VectorSource from 'ol/source/Vector'
import clone from '../../helpers/clone'
import {Fill, Stroke, Circle, Style} from 'ol/style'

import MapWrapper from '../../components/MapWrapper'
import shapeMapStyle from '../../helpers/shapeMapStyle'


function ShapeMap(props) {

  const [ features, setFeatures ] = useState()
  const [ style, setStyle ] = useState()

  let path_prefix = clone(window, "shape_url")

  const shape_kml_url = id => { // use consts or let
    return path_prefix + "/" + id + ".kml"
  }

  useEffect( () => {
    if (props.shapeId) {
      fetch(shape_kml_url(props.shapeId))
        .then(response => response.text())
        .then( (fetchedFeatures) => {
          //  use options to convert feature from EPSG:4326 to EPSG:3857
          const wktOptions = {
            dataProjection: 'EPSG:4326',
            featureProjection: 'EPSG:3857'
          }

          var style = shapeMapStyle({})
          const parsedFeatures = new KML({defaultStyle: style}).readFeatures(fetchedFeatures, wktOptions)
          setFeatures(parsedFeatures)
        })
    }
  },[props.shapeId])

  return (
    <div className="openlayers_map" style={props.shapeId ? {} : { display: 'none' }}>
      <MapWrapper features={features} style={style}/>
    </div>
  )
}

export default ShapeMap
