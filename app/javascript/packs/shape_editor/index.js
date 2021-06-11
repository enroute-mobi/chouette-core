import '../../helpers/polyfills'

import React, { useEffect, useReducer } from 'react'
import { render } from 'react-dom'
import { isEmpty } from 'lodash'

import { Fill, Stroke, Circle, Style } from 'ol/style'
import KML from 'ol/format/KML'
import Collection from 'ol/Collection'
import Modify from 'ol/interaction/Modify'
import Draw from 'ol/interaction/Draw'
import Snap from 'ol/interaction/Snap'

import { reducer, initialState, actions } from './reducer'
import MapWrapper from '../../components/MapWrapper'
import List from './list'

// parse fetched geojson into OpenLayers features
//  use options to convert feature from EPSG:4326 to EPSG:3857
const wktOptions = {
  dataProjection: 'EPSG:4326',
  featureProjection: 'EPSG:3857'
}

const defaultStyle = new Style({
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

const fromOLToTurfCoordinates = geometry => geometry.clone().transform('EPSG:3857', 'EPSG:4326').getCoordinates()

function ShapeEditorMap() {
  // set intial state
  const [state, dispatch] = useReducer(reducer, initialState)
  const interactions = [state.draw, state.modify]

  // Handlers
  const handleMapInit = async (map, featuresLayer) => {  
    const response = await fetch('/shape_editor/get_waypoints')
    const fetchedFeatures = await response.text()

    const features = new KML({ extractStyles: false, defaultStyle }).readFeatures(fetchedFeatures, wktOptions)
    const line = features.find(f => f.getGeometry().getType() == 'LineString')
    const waypoints = features.filter(f => f.getGeometry().getType() == 'Point')

    dispatch(actions.setLine(line))
    dispatch(actions.setWaypoints(waypoints))

    dispatch(actions.setAttributes({ map, featuresLayer, features }))
  }

  const handleNewPoint = e => {
    console.log('handleNewPoint', e)

    actions.addNewPoint(e.feature.getGeometry())
  }

  const handleMovePoint = e => {
    console.log('handleMovePoint', e)

    actions.movePoint(e.feature.getGeometry())
  }

  // Helpers
  const hasWaypoints = () => !isEmpty(state.waypoints)

  // useEffect hooks
  useEffect(() => {
    if (!!state.featuresLayer && hasWaypoints()) {
      const source = state.featuresLayer.getSource()
      const modify = new Modify({ features: new Collection(state.waypoints) })
      const draw = new Draw({ source, type: 'Point' })
      const snap = new Snap({ source })
      const interactions = [modify, draw, snap]

      interactions.forEach(i => state.map.addInteraction(i))

      dispatch(actions.setAttributes({ draw, modify, snap }))
    }
  }, [state.featuresLayer, state.waypoints])

  useEffect(() => {
    state.draw?.on('drawend', handleNewPoint)
    state.modify?.on('modifyend', handleMovePoint)
  }, interactions)

  useEffect(() => {
    if (hasWaypoints()) {
      state.waypoints.forEach(w => console.log(w.getProperties().name, w.getProperties().distanceFromStart))
    }
  }, [state.waypoints])

  return (
    <div className="page-content">
      <div className="container-fluid">
        <div className="row">
          <div className="col-md-6">
            <h4 className="underline">Liste</h4>
            <List waypoints={state.waypoints} />
          </div>
          <div className="col-md-6">
          <h4 className="underline">Carte</h4>
            <div className="openlayers_map">
              <MapWrapper features={state.features} style={state.style} onInit={handleMapInit} />
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
