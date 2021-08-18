import { flow } from 'lodash'

import {
  bearing,
  center,
  degreesToRadians,
  featureReduce,
  getCoord,
  getCoords,
  length,
  lineChunk,
  lineSlice,
  lineString,
  nearestPointOnLine,
  point,
  segmentReduce,
  simplify,
  toMercator
} from '@turf/turf'

import { Fill, RegularShape, Style } from 'ol/style'
import Point from 'ol/geom/Point'

import handleRedirect from '../../helpers/redirect'

import store from './shape.store'
import { getTurfLine } from './shape.selectors'

export const convertCoords = feature =>
  feature
  .getGeometry()
  .clone()
  .transform('EPSG:3857', 'EPSG:4326')
  .getCoordinates()

export const isLine = feature => feature.getGeometry().getType() == 'LineString'
export const isWaypoint = feature => feature.getGeometry().getType() == 'Point'

export const setDistanceFromStart = waypoint => {
  store.getState(state => {
    const turfLine = getTurfLine(state)

    if (!turfLine) return

    const firstPoint = point(getCoords(turfLine)[0])

     // Create a line slice from the beginning to the current waypoint to determine the length of this "subLine"
      const subLine = lineSlice(
        firstPoint,
        nearestPointOnLine(turfLine, convertCoords(waypoint)),
        turfLine
      )

      waypoint.set('distanceFromStart', length(subLine))
  })
}

export const getArrowStyles = feature => {
  const line = lineString(convertCoords(feature))
  const chunks = lineChunk(line, length(line) / 7)
  const arrowRotation = flow(getCoords, coords => bearing(...coords), degreesToRadians)
  const arrowCoords = flow(center, toMercator, getCoord)

  return featureReduce(chunks, (styles, chunk) => {
    const segments = segmentReduce(chunk, (collection, currentSegment) => [...collection, currentSegment], [])
    const midSegment = segments[Math.floor(segments.length / 2)]

    return [
      ...styles,
      new Style({
        geometry: new Point(arrowCoords(midSegment)),
        image: new RegularShape({
          fill: new Fill({ color: 'red' }),
          points: 3,
          radius: 8,
          rotation: arrowRotation(midSegment)
        })
      })
    ]
  }, [])

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
