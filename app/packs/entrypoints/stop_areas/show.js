import { Path } from 'path-parser'
import { Map, View } from 'ol'
import { Tile as TileLayer, Vector as VectorLayer } from 'ol/layer'
import Group from 'ol/layer/Group'
import { OSM, XYZ, Vector as VectorSource } from 'ol/source'
import { ScaleLine, Zoom, ZoomSlider } from 'ol/control'
import { getCenter, isEmpty as isEmptyExtent, extend as extendExtent, buffer as bufferExtent } from 'ol/extent'
import LayerSwitcher from 'ol-layerswitcher'

import geoJSON from '../../src/helpers/geoJSON'
import { i18n } from '../../src/i18n'
import * as MapStyles from '../../src/helpers/open_layers/map_styles' // Load styles methods

const path = new Path('/workbenches/:workbenchId/stop_area_referential/stop_areas/:id')
const params = path.partialTest(location.pathname)

const baseURL = path.build(params)
// Use legacy consolidated map endpoint
const stopAreaURL = `${baseURL}/map.geojson`
const connectionLinksURL = `${baseURL}/fetch_connection_links.geojson`

const LAYER_I18N_MAP = {
  stop_area: 'activerecord.models.stop_area.zero',
  connection_link: 'activerecord.models.connection_link.zero',

  parent: 'activerecord.attributes.stop_area.parent',
  children: 'activerecord.attributes.stop_area.children',
  referent: 'activerecord.attributes.stop_area.referent',
  particulars: 'activerecord.attributes.stop_area.specific_stops',
  ancestors: 'activerecord.attributes.stop_area.ancestors'
}

const getLayerTitle = (key) => {
  const mapped = LAYER_I18N_MAP[key]
  if (mapped) return i18n.t(mapped)
  return i18n.t(`stop_areas.map.layers.${key}`)
}
const getGroupTitle = () => i18n.t('stop_areas.map.groups.data')
const getBaseGroupTitle = () => i18n.t('stop_areas.map.groups.base')

function fitToLayers(map, layersByKey, visibility) {
  // Compute combined extent of all visible layers
  let combined
  Object.entries(layersByKey).forEach(([key, layer]) => {
    if (visibility[key] !== false) {
      const extent = layer.getSource().getExtent()
      if (!combined) combined = extent
      else combined = extendExtent(combined, extent)
    }
  })
  if (combined) {
    if (isEmptyExtent(combined) || (combined[0] === combined[2] && combined[1] === combined[3])) {
      const center = getCenter(combined)
      const buffered = bufferExtent([center[0], center[1], center[0], center[1]], 250) // ~500m width
      map.getView().fit(buffered, { padding: [100, 100, 100, 100], maxZoom: 18 })
    } else {
      map.getView().fit(combined, { padding: [100, 100, 100, 100], maxZoom: 18 })
    }
  }
}

async function init() {
  const container = document.getElementById('connection_link_map')
  if (!container) return

  // Base map layers (OSM + Satellite)
  const osmLayer = new TileLayer({
    title: 'OpenStreetMap',
    type: 'base',
    visible: true,
    source: new OSM({ attributions: '\u00A9 OpenStreetMap contributors' })
  })
  const satelliteLayer = new TileLayer({
    title: 'Satellite',
    type: 'base',
    visible: false,
    source: new XYZ({
      attributions: 'Tiles \u00A9 Esri — Source: Esri, i-cubed, USDA, USGS, AEX, GeoEye, Getmapping, Aerogrid, IGN, IGP, UPR-EGP, and the GIS User Community',
      url: 'https://services.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
    })
  })
  const baseGroup = new Group({
    title: getBaseGroupTitle(),
    fold: 'open',
    layers: [osmLayer, satelliteLayer]
  })
  const map = new Map({
    layers: [baseGroup],
    view: new View({ center: [0, 0], zoom: 2 }),
    controls: [new ScaleLine(), new Zoom(), new ZoomSlider()]
  })
  map.setTarget(container)

  // Fetch both sources
  const [stopAreaFC, connectionFC] = await Promise.all([
    fetch(stopAreaURL).then(r => r.json()),
    fetch(connectionLinksURL).then(r => r.json())
  ])

  // Read features (projection handled by helper)
  const stopAreaFeatures = geoJSON.readFeatures(stopAreaFC)
  const connectionFeatures = Array.isArray(connectionFC)
    ? connectionFC.map(fc => geoJSON.readFeatures(fc)).flat()
    : geoJSON.readFeatures(connectionFC)

  // Group by layer/type
  const allFeatures = [...stopAreaFeatures, ...connectionFeatures].filter(f => !!f.getGeometry())
  const groups = {}
  allFeatures.forEach(f => {
    const key = f.get('layer') || f.get('type') || 'other'
    if (!groups[key]) groups[key] = []
    groups[key].push(f)
  })

  // Create group for data layers
  const layersByKey = {}
  const visibility = {}
  const dataLayers = []
  Object.entries(groups).forEach(([key, feats]) => {
    const source = new VectorSource({ features: feats })
    const layer = new VectorLayer({ source, style: MapStyles[`${key}_style`], title: getLayerTitle(key), visible: true })
    layersByKey[key] = layer
    visibility[key] = true
    dataLayers.push(layer)
  })
  const dataGroup = new Group({ title: getGroupTitle(), fold: 'open', layers: dataLayers })
  map.addLayer(dataGroup)

  // Add LayerSwitcher control
  const layerSwitcher = new LayerSwitcher({
    activationMode: 'click',
    startActive: false,
    groupSelectStyle: 'children'
  })
  map.addControl(layerSwitcher)
  // Panel rendering is handled by the control itself

  // Track visibility changes to refit on toggle via LayerSwitcher
  Object.keys(layersByKey).forEach(key => {
    const layer = layersByKey[key]
    layer.on('change:visible', () => {
      visibility[key] = layer.getVisible()
      setTimeout(() => fitToLayers(map, layersByKey, visibility), 0)
    })
  })

  // Initial fit
  setTimeout(() => fitToLayers(map, layersByKey, visibility), 100)
}

document.addEventListener('DOMContentLoaded', init)

