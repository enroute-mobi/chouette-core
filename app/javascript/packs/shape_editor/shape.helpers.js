import { add, each, flow, map } from 'lodash'

import {
  along,
  bearing,
  degreesToRadians,
  getCoord,
  getCoords,
  length,
  lineSlice,
  lineString,
  nearestPointOnLine,
  segmentReduce,
  simplify,
  toMercator,
  toWgs84
} from '@turf/turf'

import Feature from 'ol/Feature'
import { Circle, Fill, RegularShape, Stroke, Style } from 'ol/style'
import Point from 'ol/geom/Point'

import handleRedirect from '../../helpers/redirect'

import store from './shape.store'
import { getLineSections, getWaypointsCoords } from './shape.selectors'

export const getFeatureCoordinates = feature => {
  const geo = feature.getGeometry()
  const coords = geo.getCoordinates()

  switch(geo.getType()) {
    case 'Point':
      return toWgs84(coords)
    case 'LineString':
      return map(coords, toWgs84)
    default:
      throw(`Unsupported geometry type: ${geo.getType()}`)
  }
}

export const isLine = feature => feature.getGeometry().getType() == 'LineString'
export const isWaypoint = feature => feature.getGeometry().getType() == 'Point'

export const getStyles = () => ({
  points: {
    shapeWaypoint: new Style({
      image: new Circle({
        radius: 8,
        stroke: new Stroke({ color: 'white', width: 2 }),
        fill: new Fill({ color: 'red' })
      })
    }),
    shapeConstraint: new Style({
      image: new Circle({
        radius: 8,
        stroke: new Stroke({ color: 'red', width: 2 }),
        fill: new Fill({ color: 'white' })
      })
    }),
    route: new Style({
      image: new Circle({
        radius: 5,
        stroke: new Stroke({ color: 'black', width: 0.75 }),
        fill: new Fill({ color: 'rgba(255, 255, 255, 0.5)' })
      })
    }),
  },
  lines: {
    route: new Style({
      stroke: new Stroke({
        color: 'black',
        width: 1,
        lineDash: [6, 6],
        lineDashOffset: 6
      })
    }),
    shape: _feature => {
      const state = store.getStateSync()
    
      const styles = [
        new Style({
          stroke: new Stroke({
            color: 'red',
            width: 1.5
          })
        })
      ]

      each(
        getLineSections(state),
        chunk => {
          const segments = segmentReduce(chunk, (collection, currentSegment) => [...collection, currentSegment], [])
          const midSegment = segments[Math.floor(segments.length / 2)]

          styles.push(getArrowStyle(midSegment))
        }
      )

      return styles
    }
  }
})

const getLineMidpoint = line => along(line, length(line) / 2)

export const getArrowStyle = segment => {
  const arrowRotation = flow(getCoords, coords => bearing(...coords), degreesToRadians)
  const arrowCoords = flow(getLineMidpoint, toMercator, getCoord)
  
  return new Style({
    geometry: new Point(arrowCoords(segment)),
    image: new RegularShape({
      fill: new Fill({ color: 'red' }),
      points: 3,
      radius: 8,
      rotation: arrowRotation(segment)
    })
  })
}

export const getWaypointToInsertAttributes = async ([startCoords, endCoords]) => {
  const styles = getStyles()
  const state = await store.getStateAsync()

  const waypointsCoords = getWaypointsCoords(state)
  const line = lineString(waypointsCoords)
  const linePoint = nearestPointOnLine(line, toWgs84(startCoords))
  const { index } = linePoint.properties

  const newLine = lineSlice(getCoords(line)[0], getCoord(linePoint), line)
  const other = lineSlice(getCoords(line)[0], waypointsCoords[index], line)

  const insertIndex = add(
    index + 1,
    Boolean(length(newLine) > length(other))
  )

  const waypoint = new Feature({
    geometry: new Point(endCoords),
    type: 'constraint',
  })

  waypoint.setStyle(styles.points.shapeConstraint)

  return { waypoint, insertIndex }
}

export const simplifyGeoJSON = data => simplify(data, { tolerance: 0.0001, highQuality: true }) // We may want to have a dynamic tolerance

export const lineId = 'line'

export const wktOptions = { //  use options to convert feature from EPSG:4326 to EPSG:3857
  dataProjection: 'EPSG:4326',
  featureProjection: 'EPSG:3857'
}

export const submitFetcher = async (url, isEdit, payload) => {
  const method = isEdit ? 'PUT' : 'POST'

  const response = await fetch(url, {
    method,
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json', 
      'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').attributes.content.value
    },
    body: JSON.stringify(payload)
  })

  handleRedirect(() => {
    const { sessionStorage } = window
    const previousAction = isEdit ? 'shape-update' : 'shape-create'
    
    sessionStorage.setItem('previousAction', previousAction) // Being used in JP react app to display or not a flash message
    }
  )(response)

  const data = await response.json() 

  if (!response.ok) {
    throw data['errors']
  }

  return data
}
