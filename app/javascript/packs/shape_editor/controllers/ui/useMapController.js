import { useEffect } from 'react'

import Collection from 'ol/Collection'
import Modify from 'ol/interaction/Modify'
import Draw from 'ol/interaction/Draw'
import Snap from 'ol/interaction/Snap'
import { Circle, Fill, Stroke, Style } from 'ol/style'

import { first, isEmpty, pick, tap } from 'lodash'

import { useStore } from '../../../../helpers/hooks'

const constraintStyle = new Style({
  image: new Circle({
    radius: 2.5,
    stroke: new Stroke({ color: 'black', width: 1 }),
    fill: new Fill({ color: 'rgba(255, 255, 255, 0.5)' })
   })
})

const mapStateToProps = state =>
  pick(state, [
    'addNewPoint',
    'featuresLayer',
    'map',
    'moveWaypoint',
    'setAttributes',
    'waypoints'
  ])

export default function useMapInteractions(store) {
  // Store
  const [
    { addNewPoint, featuresLayer, map, moveWaypoint, setAttributes, waypoints }
  ] = useStore(store, mapStateToProps)

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
    tap(first(e.features.getArray()), waypoint => {
      moveWaypoint(
        waypoint.getId(),
        waypoint.getGeometry().getCoordinates()
      )

      setAttributes({ shouldUpdateLine: true })
    })
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