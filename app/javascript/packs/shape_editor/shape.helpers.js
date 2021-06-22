import { lineString, simplify } from '@turf/turf'

export const convertCoords = feature =>
  feature
  .getGeometry()
  .clone()
  .transform('EPSG:3857', 'EPSG:4326')
  .getCoordinates()

export const buildTurfLine = line => lineString(convertCoords(line))

export const simplifyGeoJSON = data => simplify(data, { tolerance: 0.0001, highQuality: true }) // We may want to have a dynamic tolerance