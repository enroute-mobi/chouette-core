import { Path } from 'path-parser'
import { Map, View } from 'ol'
import { Tile as TileLayer, Vector as VectorLayer } from 'ol/layer'
import Group from 'ol/layer/Group'
import { OSM, XYZ, Vector as VectorSource } from 'ol/source'
import { ScaleLine, Zoom, ZoomSlider } from 'ol/control'
import { getCenter, isEmpty as isEmptyExtent, extend as extendExtent, buffer as bufferExtent } from 'ol/extent'
import LayerSwitcher from 'ol-layerswitcher'

// Import des icônes
import stopAreaIcon from 'images/icons/map_stop_area.svg'
import parentIcon from 'images/icons/map_parent.svg'
import childrenIcon from 'images/icons/map_children.svg'
import siblingsIcon from 'images/icons/map_siblings.svg'
import referentIcon from 'images/icons/map_referent.svg'
import particularsIcon from 'images/icons/map_particulars.svg'
import otherParticularsIcon from 'images/icons/map_other_particulars.svg'

import geoJSON from '../../src/helpers/geoJSON'
import { i18n } from '../../src/i18n'
import * as MapStyles from '../../src/helpers/open_layers/map_styles' // Load styles methods

const path = new Path('/workbenches/:workbenchId/stop_area_referential/stop_areas/:id')
const params = path.partialTest(location.pathname)

const baseURL = path.build(params)
// Use legacy consolidated map endpoint
const stopAreaURL = `${baseURL}.geojson`

const LAYER_I18N_MAP = {
  stop_area: 'activerecord.models.stop_area.zero',
  connection_link: 'activerecord.models.connection_link.zero',
  parent: 'activerecord.attributes.stop_area.parent',
  children: 'activerecord.attributes.stop_area.children',
  referent: 'activerecord.attributes.stop_area.referent',
  particulars: 'activerecord.attributes.stop_area.specific_stops',
  ancestors: 'activerecord.attributes.stop_area.ancestors',
  siblings: 'activerecord.attributes.stop_area.siblings'
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
  const container = document.getElementById('stop_area_map')
  if (!container) return

  // Base map layers (OSM + Satellite)
  const osmLayer = new TileLayer({
    title: 'OpenStreetMap',
    type: 'base',
    visible: true,
    source: new OSM({ attributions: '\u00A9 OpenStreetMap contributors' })
  })

  // Satellite layer
  /*

  const satelliteLayer = new TileLayer({
    title: 'Satellite',
    type: 'base',
    visible: false,
    source: new XYZ({
      url: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
      attributions: 'Tiles &copy; Esri &mdash; Source: Esri, i-cubed, USDA, USGS, AEX, GeoEye, Getmapping, Aerogrid, IGN, IGP, UPR-EGP, and the GIS User Community'
    })
  })
  */


  const baseGroup = new Group({
    title: getBaseGroupTitle(),
    fold: 'open',
    layers: [osmLayer]
    // layers: [osmLayer, satelliteLayer]
  })

  // Create view with reasonable default values
  const view = new View({
    center: [0, 0],
    zoom: 2,
    minZoom: 2,
    maxZoom: 18
  });

  // Create map

  const map = new Map({
    layers: [baseGroup],
    view: view,
    controls: [
      new ScaleLine(),
      new Zoom(),
      new ZoomSlider()
    ]
  })
  map.setTarget(container)

  // Fetch both sources
  const stopAreaFC = await fetch(stopAreaURL).then(r => r.json())

  // Read features (projection handled by helper)
  const stopAreaFeatures = geoJSON.readFeatures(stopAreaFC)

  // Group by layer/type
  const groups = {}
  stopAreaFeatures.forEach(f => {
    if (f.getGeometry()) {
      const key = f.get('layer') || f.get('type') || 'other'
      if (!groups[key]) groups[key] = []
      groups[key].push(f)
    }
  })

  // Create layers
  const layersByKey = {}
  const visibility = {}
  const dataLayers = []

  Object.entries(groups).forEach(([key, features]) => {
    const source = new VectorSource({ features })
    const layer = new VectorLayer({
      source,
      style: MapStyles[`${key}_style`] || MapStyles.stop_area_style,
      title: getLayerTitle(key),
      visible: true
    })

    layersByKey[key] = layer
    visibility[key] = true
    dataLayers.push(layer)
  })
  const dataGroup = new Group({ title: getGroupTitle(), fold: 'open', layers: dataLayers })
  map.addLayer(dataGroup)

  // Add layer switcher
  const layerSwitcher = new LayerSwitcher({
    activationMode: 'click',
    startActive: false,
    groupSelectStyle: 'none',
    tipLabel: i18n.t('map.controls.layers')
  });

  // Hide the li element corresponding to the stop_area layer
  const hideStopAreaLayer = () => {
    const layerElements = document.querySelectorAll('.layer-switcher li.layer');
    layerElements.forEach(li => {
      const label = li.querySelector('label');
      if (label && label.textContent === getLayerTitle('stop_area')) {
        li.style.display = 'none';
      }
    });
  };

  // Wait for LayerSwitcher to be rendered
  setTimeout(hideStopAreaLayer, 100);

  // Reapply after each panel opening
  const observer = new MutationObserver(hideStopAreaLayer);
  observer.observe(document.body, { childList: true, subtree: true });

  map.addControl(layerSwitcher);

  // Adjust LayerSwitcher container z-index
  const layerSwitcherElement = document.querySelector('.layer-switcher');
  if (layerSwitcherElement) {
    layerSwitcherElement.style.zIndex = '2000';
  }

  // Legend style configuration
  const legendStyle = {
    position: 'absolute',
    bottom: '10px',
    left: '10px',
    right: '10px',
    backgroundColor: 'rgba(255, 255, 255, 0.9)',
    padding: '4px 8px',
    borderRadius: '4px',
    boxShadow: '0 1px 3px rgba(0, 0, 0, 0.15)',
    zIndex: '1000',
    maxWidth: '80%',
    overflowX: 'auto',
    overflowY: 'hidden',
    whiteSpace: 'nowrap',
    fontSize: '0.9em'
  };

  // Create legend element
  const legend = Object.assign(document.createElement('div'), {
    className: 'ol-legend'
  });
  Object.assign(legend.style, legendStyle);

  // Add legend to map
  const mapElement = map.getTargetElement();
  mapElement.style.position = 'relative';
  mapElement.appendChild(legend);

  // Update legend
  const updateLegend = () => {
    const list = document.createElement('div');
    Object.assign(list.style, {
      display: 'flex',
      flexDirection: 'row',
      gap: '12px',
      padding: '2px 0'
    });

    legend.innerHTML = '';
    legend.appendChild(list);
      // Map layer keys to icons
      const iconMap = {
        'stop_area': stopAreaIcon,
        'parent': parentIcon,
        'children': childrenIcon,
        'siblings': siblingsIcon,
        'particulars': particularsIcon,
        'other_particulars': otherParticularsIcon,
        'referent': referentIcon
      };

      // Add legend items for visible layers
      Object.entries(layersByKey).forEach(([key, layer]) => {
        if (layer.getVisible() && iconMap[key]) {
          const container = document.createElement('div');
          Object.assign(container.style, {
            display: 'inline-flex',
            alignItems: 'center',
            gap: '4px',
            padding: '3px 6px',
            border: '1px solid #f0f0f0',
            borderRadius: '3px',
            backgroundColor: 'white',
            margin: '0 2px'
          });

          // Create icon and text
          const icon = Object.assign(document.createElement('img'), {
            src: iconMap[key],
            alt: key,
            style: 'width: 24px; height: 24px; object-fit: contain;'
          });

          const text = document.createElement('span');
          text.textContent = i18n.t(LAYER_I18N_MAP[key] || `map.legend.${key}`);

          container.append(icon, text);
          list.appendChild(container);
      }
    });

    legend.appendChild(list);
  };

  // Update legend when layer visibility changes
  Object.values(layersByKey).forEach(layer => {
    layer.on('change:visible', updateLegend);
  });

  // Initial update
  updateLegend();

  // Track visibility changes to refit on toggle via LayerSwitcher
  Object.keys(layersByKey).forEach(key => {
    const layer = layersByKey[key];
    layer.on('change:visible', () => {
      visibility[key] = layer.getVisible();
      // Delay to ensure visibility is updated
      setTimeout(() => fitToLayers(map, layersByKey, visibility), 100);
    });
  });

  // Initial view adjustment after a short delay
  setTimeout(() => {
    try {
      fitToLayers(map, layersByKey, visibility);
      // Force view refresh
      map.updateSize();
    } catch (e) {
      console.error('Error during initial view adjustment:', e);
    }
  }, 300);
}

document.addEventListener('DOMContentLoaded', init)

