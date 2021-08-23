import { add, find, flow, map, partialRight, sortBy } from 'lodash'

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
  pointToLineDistance,
  segmentReduce,
  simplify,
  toMercator,
  toWgs84
} from '@turf/turf'

import Feature from 'ol/Feature'
import { Fill, RegularShape, Style } from 'ol/style'
import Point from 'ol/geom/Point'

import handleRedirect from '../../helpers/redirect'

export const getFeatureCoordinates = feature => {
  const geo = feature.getGeometry()
  const coords = geo.getCoordinates()

  switch (geo.getType()) {
    case 'Point':
      return toWgs84(coords)
    case 'LineString':
      return map(coords, toWgs84)
    default:
      throw (`Unsupported geometry type: ${geo.getType()}`)
  }
}

const collectionToArray = coll => coll.getArray()
const getLayers = obj => obj?.getLayers() || { getArray: () => [] }
const getSource = obj => obj?.getSource()

const getLayer = key => flow(getLayers, collectionToArray, layers => find(layers, l => l.get(key)))

export const getStaticlayer = getLayer('static')
export const getInteractiveLayerGroup = getLayer('interactive')
export const getLineLayer = flow(getInteractiveLayerGroup, getLayer('line'))
export const getWaypointsLayer = flow(getInteractiveLayerGroup, getLayer('waypoints'))

export const getLineSource = flow(getLineLayer, getSource)
export const getWaypointsSource = flow(getWaypointsLayer, getSource)

export const getLine = flow(getLineSource, source => source.getFeatureById('line'))
export const getWaypoints = flow(getWaypointsSource, source => source.getFeatures())

export const getLineCoords = flow(getLine, getFeatureCoordinates)
export const getWaypointsCoords = flow(getWaypoints, partialRight(map, getFeatureCoordinates))

export const getLineSections = map => {
  try {
    const line = flow(getLineCoords, lineString)(map)
    const waypointsLine = flow(getWaypointsCoords, lineString)(map)

    return segmentReduce(
      waypointsLine,
      (result, segment) => [...result, lineSlice(...getCoords(segment), line)],
      []
    )
  } catch(e) {
    return []
  }
}

const getLineMidpoint = line => along(line, length(line) / 2)

export const getArrowStyles = map =>
  getLineSections(map).map(section => {
    const coords = flow(getLineMidpoint, getCoord)(section)

    const segments = segmentReduce(section, (collection, segment) => [
      ...collection,
      { ...segment, properties: { ...segment.properties, distance: pointToLineDistance(coords, segment) } }
    ], [])

    const midSegment = sortBy(segments, segment => segment.properties.distance)[0]

    return getArrowStyle(midSegment, coords)
  })

const getArrowStyle = (segment, coords) => {
  const arrowRotation = flow(getCoords, coords => bearing(...coords), degreesToRadians)
  
  return new Style({
    geometry: new Point(toMercator(coords)),
    image: new RegularShape({
      fill: new Fill({ color: 'red' }),
      points: 3,
      radius: 8,
      rotation: arrowRotation(segment)
    })
  })
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

export const getSubmitPayload = state => ({
  shape: {
    name: state.name,
    coordinates: getLineCoords(stae.map),
    waypoints: map(getWaypoints(state.map), (w, position) => ({
      name: w.get('name'),
      position,
      waypoint_type: w.get('type'),
      coordinates: getFeatureCoordinates(w)
    }))
  }
})
