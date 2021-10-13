import { bindAll, find, flatten, flow, nth, partialRight, reduce, sortBy } from 'lodash'

import {
  along,
  bearing,
  coordAll,
  degreesToRadians,
  featureCollection,
  featureReduce,
  getCoord,
  getCoords,
  length,
  lineSlice,
  lineString,
  pointToLineDistance,
  segmentReduce,
  simplify,
  toMercator
} from '@turf/turf'

import { Fill, RegularShape, Style } from 'ol/style'
import Point from 'ol/geom/Point'
import GeoJSON from 'ol/format/GeoJSON'

import handleRedirect from '../../helpers/redirect'

export const wktOptions = { //  use options to convert feature from EPSG:4326 to EPSG:3857
  dataProjection: 'EPSG:4326',
  featureProjection: 'EPSG:3857'
}

export const mapFormat = bindAll(
  new GeoJSON(wktOptions),
  [
    'readFeature',
    'readFeatures',
    'writeFeatureObject',
    'writeFeaturesObject'
  ]
)

const log = (message = '') => data => {
  console.log(message, data)
  return data
}

const reduceToMapFunc = reduceFunc => (object, mapperFunc) =>
    reduceFunc(
      object,
      (result, value, index) => [...result, mapperFunc(value, index)],
      []
    )

export const featureMap = reduceToMapFunc(featureReduce)
export const segmentMap = reduceToMapFunc(segmentReduce)

export const getLayers = obj => obj?.getLayers() || { getArray: () => [] }
export const getSource = obj => obj?.getSource()
export const getLayer = key => flow(getLayers, layers => layers.getArray(), layers => find(layers, l => l.get(key)))

const getTolerance = (() => {
  const tolerances = [1, 0.1, 0.01, 0.001, 0.0009, 0.0007, 0.0005, 0.0003, 0.0001, 0]
  
  return view => {
    const percentage = (view.getZoom() - view.getMinZoom()) / (view.getMaxZoom() - view.getMinZoom())
    const index = Math.ceil((tolerances.length - 1) * percentage)

    return nth(tolerances, index)
  }
})()

/**
 * Simplify each section based on map's current zoom
 * @param {GeoJSON} sectionCollection A Feature Collection of LineString
 * @param {object} view The OL View object
 * @return {GeoJSON} A simplified version of the sectionCollection transformed into a LineString
 */
export const simplifyGeometry = (sectionCollection, view) => {
  const sectionMapper = (object, _i) =>
    flow(
      partialRight(simplify, { tolerance: getTolerance(view), highQuality: true }),
      getCoords
    )(object)

  return flow(
    partialRight(featureMap, sectionMapper),
    flatten,
    lineString
  )(sectionCollection)
}

/**
 * Compute sections based on a LineString and a collection of points
 * @param {GeoJSON} line A LineString Feature
 * @param {GeoJSON} waypoints A Feature Collection of points
 * @return {GeoJSON} A Feature Collection of LineString
 */
export const getLineSections = (line, waypoints) => {
  const sectionsReducer = coords => reduce(
    coords,
    (result, coord, index, coll) => {
      const nextCoord = coll[index + 1]

      if (!Boolean(nextCoord)) return result

      return [...result, lineSlice(coord, nextCoord, line)]
    },
    []
  )

  return flow(coordAll, sectionsReducer, featureCollection)(waypoints)
}

export const getLineMidpoint = line => along(line, length(line) / 2)

/**
 * Compute Line Arrow Styles that display the line direction
 * @param {GeoJSON} sectionCollection A Feature Collection of LineString
 * @return {array} A array of style objects
 */
export const getArrowStyles = flow(
  partialRight(
    featureMap,
    section => {
      const midPointCoords = flow(getLineMidpoint, getCoord)(section)

      const segments = segmentMap(
        section,
        ({ properties, ...segment }) => ({
          ...segment,
          properties: { ...properties, distance: pointToLineDistance(midPointCoords, segment) }
        })
      )

      const midSegment = sortBy(segments, segment => segment.properties.distance)[0]

      return getArrowStyle(midSegment, midPointCoords)
    }
  )
)

const getArrowStyle = (segment, coords) => {
  const getArrowRotation = flow(getCoords, coords => bearing(...coords), degreesToRadians)

  return new Style({
    geometry: new Point(toMercator(coords)),
    image: new RegularShape({
      fill: new Fill({ color: 'red' }),
      points: 3,
      radius: 7,
      rotation: getArrowRotation(segment)
    })
  })
}

export const lineId = 'line'

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
