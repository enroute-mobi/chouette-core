import '../../helpers/polyfills'

import React, { useState, useEffect } from 'react'
import { render } from 'react-dom'
import { Fill, Stroke, Circle, Style } from 'ol/style'
import KML from 'ol/format/KML'
import GeometryType from 'ol/geom/GeometryType'
import ShapeEditor from './shapeEditor'
import List from './list'

function RouteMap() {
  // set intial state
  const [ features, setFeatures ] = useState([])
  const [waypoints, setWaypoints] = useState([])
  const [ style, setStyle ] = useState(new Style({}))

  // initialization - retrieve GeoJSON features from Mock JSON API get features from mock
  //  GeoJson API (read from flat .json file in public directory)
  useEffect( () => {

    fetch('/shape_editor/get_waypoints')
      .then(response => response.text())
      .then(fetchedFeatures => {

        // parse fetched geojson into OpenLayers features
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
              width: 10,
            }),
          }),
          stroke: new Stroke({
            color: 'rgba(255, 204, 0)',
            width: 10,
          }),
          fill: new Fill({
            color: 'rgba(255, 153, 0)',
          }),

        })

        const parsedFeatures = new KML({extractStyles: false, defaultStyle: style} ).readFeatures(fetchedFeatures, wktOptions)

        // set features into state (which will be passed into OpenLayers
        //  map component as props)
        setFeatures(parsedFeatures)

      })

  },[])
  useEffect(() => {
    features && setWaypoints(() => features.filter(f => f.getGeometry().getType() == 'Point'))
  },[features])

  return (
    <div className="page-content">
      <div className="container-fluid">
        <div className="row">
          <div className="col-md-6">
            <h4 className="underline">Liste</h4>
            <List waypoints={waypoints} />
          </div>
          <div className="col-md-6">
          <h4 className="underline">Carte</h4>
            <div className="openlayers_map">
              <ShapeEditor features={features} style={style} />
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}


render(
  <RouteMap />,
  document.getElementById('shape_editor')
)
