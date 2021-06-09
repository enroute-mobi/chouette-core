import '../../helpers/polyfills'

import React, { useState, useEffect } from 'react'
import { render } from 'react-dom'
import { Fill, Stroke, Circle, Style } from 'ol/style'
import KML from 'ol/format/KML'
import MapWrapper from '../../components/MapWrapper'
import Modify from 'ol/interaction/Modify'
import Draw from 'ol/interaction/Draw'
import Snap from 'ol/interaction/Snap'

import List from './list'

function ShapeEditorMap() {
  // set intial state
  const [features, setFeatures] = useState([])
  const [waypoints, setWaypoints] = useState([])
  const [map, setMap] = useState(null)
  const [source, setSource] = useState(null)
  const [ style, setStyle ] = useState(new Style({}))

  const handleMapInit = async (map, featuresLayer) => {
    setMap(map)

    featuresLayer.on('change:source', e => {
      setSource(e.target.getSource())
    })
  
    const response = await fetch('/shape_editor/get_waypoints')
    const fetchedFeatures = await response.text()

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
      })
    })

    const features = new KML({extractStyles: false, defaultStyle: style} ).readFeatures(fetchedFeatures, wktOptions)
    setFeatures(features)
    setWaypoints(() => features.filter(f => f.getGeometry().getType() == 'Point'))
  }

  useEffect(() => {
    if (!!source) {
      const interactions = [
        new Modify({ source }),
        new Draw({ source, type: 'LineString' }),
        new Snap({ source })
      ]

      interactions.forEach(i => map.addInteraction(i))
    }
  }, [source])

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
              <MapWrapper features={features} style={style} onInit={handleMapInit} />
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}


render(
  <ShapeEditorMap />,
  document.getElementById('shape_editor')
)
