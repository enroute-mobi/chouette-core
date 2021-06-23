import { useEffect } from 'react'

import Collection from 'ol/Collection'
import Modify from 'ol/interaction/Modify'
import Draw from 'ol/interaction/Draw'
import Snap from 'ol/interaction/Snap'
import { Circle, Fill, Stroke, Style } from 'ol/style'

import { isEmpty, tap } from 'lodash'

const constraintStyle = new Style({
  image: new Circle({
    radius: 2.5,
    stroke: new Stroke({ color: 'black', width: 1 }),
    fill: new Fill({ color: 'rgba(255, 255, 255, 0.5)' })
   })
})

export default function useMapInteractions(
  { featuresLayer, map, waypoints },
  { addNewPoint, setAttributes, setWaypoints }
) {
  // Helpers
  const hasWaypoints = !isEmpty(waypoints)

  // Event Handlers
  const oneNewPoint = e => {
    tap(e.feature, waypoint => {
      waypoint.set('type', 'constraint')
      waypoint.setStyle(constraintStyle)
      addNewPoint(waypoint)
    })

    setAttributes({ shouldUpdateLine: true })
  }

  const onMovedPoint = e => {
    setWaypoints(e.features.getArray())
    setAttributes({ shouldUpdateLine: true })
  }

  useEffect(() => {
    hasWaypoints &&
    featuresLayer &&
    featuresLayer.on('change:source', e => {
      tap(e.target.getSource(), source => {
        const modify = new Modify({ features: new Collection(waypoints) })
        const draw = new Draw({ source, type: 'Point' })
        const snap = new Snap({ source })
        const interactions = [modify, draw, snap]

        draw.on('drawend', oneNewPoint)
        modify.on('modifyend', onMovedPoint)

        interactions.forEach(i => map.addInteraction(i))

        setAttributes({ draw, modify, snap })
      })
    })
  }, [featuresLayer, waypoints])
}