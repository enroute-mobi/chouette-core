import { useEffect } from 'react'

import Collection from 'ol/Collection'
import Modify from 'ol/interaction/Modify'
import Draw from 'ol/interaction/Draw'
import Snap from 'ol/interaction/Snap'
import { Circle, Fill, Stroke, Style } from 'ol/style'

import { actions } from '../../shape.reducer'
import { isEmpty } from 'lodash'

const constraintStyle = new Style({
  image: new Circle({
    radius: 2.5,
    stroke: new Stroke({ color: 'black', width: 1 }),
    fill: new Fill({ color: 'rgba(255, 255, 255, 0.5)' })
   })
})

export default function useMapInteractions({ featuresLayer, map, waypoints }, dispatch) {
  // Helpers
  const hasWaypoints = !isEmpty(waypoints)

  // Event Handlers
  const oneNewPoint = e => {
    const waypoint = e.feature

    waypoint.set('type', 'constraint')
    waypoint.setStyle(constraintStyle)
  
    dispatch(actions.addNewPoint(waypoint))
    dispatch(actions.setAttributes({ shouldUpdateLine: true }))
  }

  const onMovedPoint = e => {
    dispatch(actions.setWaypoints(e.features.getArray()))
    dispatch(actions.setAttributes({ shouldUpdateLine: true }))
  }

  useEffect(() => {
    hasWaypoints &&
    featuresLayer &&
    featuresLayer.on('change:source', e => {
      const source = e.target.getSource()
      const modify = new Modify({ features: new Collection(waypoints) })
      const draw = new Draw({ source, type: 'Point' })
      const snap = new Snap({ source })

      draw.on('drawend', oneNewPoint)
      modify.on('modifyend', onMovedPoint)

      const interactions = [modify, draw, snap]

      interactions.forEach(i => map.addInteraction(i))

      dispatch(actions.setAttributes({ draw, modify, snap }))
    })
  }, [featuresLayer, waypoints])
}