import React, { useState, useEffect } from 'react';

import GeoJSON from 'ol/format/GeoJSON'
import KML from 'ol/format/KML';
import Feature from 'ol/Feature';
import VectorSource from 'ol/source/Vector'
import clone from '../../../helpers/clone'
import {Fill, Stroke, Circle, Style} from 'ol/style';


import MapWrapper from './MapWrapper'


function ShapeMapper(props) {

  const [ features, setFeatures ] = useState([])
  const [ style, setStyle ] = useState()

  let path_prefix = clone(window, "shape_kml_url")

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

          var style = new Style({
            image: new Circle({
              radius: 10,
              fill: new Fill({
                color: 'rgba(255, 153, 0)',
              }),
              stroke: new Stroke({
                color: 'rgba(255, 204, 0)',
                width: 4,
              }),
            }),
            stroke: new Stroke({
              color: 'rgba(255, 204, 0)',
              width: 4,
            }),
            fill: new Fill({
              color: 'rgba(255, 153, 0)',
            }),
          })

          const parsedFeatures = new KML({extractStyles: false, defaultStyle: style}).readFeatures(fetchedFeatures, wktOptions)
          setFeatures(parsedFeatures)
          setStyle(style)
        })
    }
  },[props.shapeId])

  return (
    <div className="openlayers_map" style={props.shapeId ? {} : { display: 'none' }}>
      <MapWrapper features={features} style={style}/>
    </div>
  )
}

export default ShapeMapper
