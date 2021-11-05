import { bindAll, find, flatten, flow, partialRight, reduce } from 'lodash'

import {
  bboxPolygon,
  booleanContains,
  booleanIntersects,
  coordAll,
  featureCollection,
  featureReduce,
  getCoords,
  lineSlice,
  lineString,
  segmentReduce,
  simplify,
  toWgs84
} from '@turf/turf'

import GeoJSON from 'ol/format/GeoJSON'

import handleRedirect from '../../src/helpers/redirect'

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

const reduceToMapFunc = reduceFunc =>
  (object, mapperFunc) =>
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

const getTolerance = zoom => {
  if (zoom < 10) {
    return 1
  } else if (zoom >= 10 && zoom < 11) {
    return 0.01
  } else if (zoom >= 11 && zoom < 12) {
    return 0.001
  } else if (zoom >= 12 && zoom < 13) {
    return 0.0005
  } else if (zoom >= 13 && zoom < 14) {
    return 0.0001
  } else {
    return 0
  }
}

/**
 * Simplify each section based on map's current zoom
 * @param {GeoJSON} sectionCollection A Feature Collection of LineString
 * @param {object} view The OL View object
 * @return {GeoJSON} A simplified version of the sectionCollection transformed into a LineString
 */
export const simplifyGeometry = (sectionCollection, map) => {
  const view = map.getView()

  const simplifySection = (section, tolerance) => simplify(section, { tolerance, highQuality: true })

  const extent = flow(
    view.calculateExtent.bind(view),
    bboxPolygon,
    toWgs84
  )(map.getSize())

  const sectionMapper = section => {
    const isInExtent = booleanContains(extent, section) || booleanIntersects(extent, section)

    return flow(
      section => simplify(section, {
        tolerance: isInExtent ? getTolerance(view.getZoom()) : 1,
        highQuality: true
      }),
      getCoords
    )(section)
  }

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

  handleRedirect(status => {
    // used in JP react app to display or not a flash message
    sessionStorage.setItem(
      'previousAction',
      JSON.stringify({
        resource: 'shape',
        action: isEdit ? 'update' : 'create',
        status
      })
    )
  })(response)

  const data = await response.json()

  if (!response.ok) {
    throw data['errors']
  }

  return data
}
