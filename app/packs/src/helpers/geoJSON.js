import GeoJSON from 'ol/format/GeoJSON'

export default new GeoJSON({ dataProjection: 'EPSG:4326', featureProjection: 'EPSG:3857' })
