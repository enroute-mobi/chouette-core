import _ from 'lodash'
import React, { useEffect, useCallback } from 'react'
import { Map, Feature, View } from 'ol'
import { Tile as TileLayer, Vector as VectorLayer } from 'ol/layer'
import { OSM, Vector as VectorSource } from 'ol/source'
import { Point } from 'ol/geom'
import { Circle, Fill, Style } from 'ol/style'
import { ScaleLine } from 'ol/control'
import { defaults, Select } from 'ol/interaction'
import { fromLonLat } from 'ol/proj'

import { Path } from 'path-parser'
import PropTypes from 'prop-types'

import geoJSON from '../../helpers/geoJSON'

const getStyles = () => ({
  default: new Style({
    image: new Circle(({
      radius: 4,
      fill: new Fill({
        color: '#004d87'
      })
    }))
  }),
  selected: new Style({
    image: new Circle(({
      radius: 6,
      fill: new Fill({
        color: '#da2f36'
      })
    }))
  })
})

export default function StopPointsMap(props) {
  const styles = getStyles()
  const { olMap } = props.value

  const feature = new Feature({
    geometry: new Point(fromLonLat([parseFloat(props.value.longitude), parseFloat(props.value.latitude)]))
  })

  const centerLayer = new VectorLayer({
    source: new VectorSource({
      features: [feature]
    }),
    style: styles.selected,
    zIndex: 2
  })

  const vectorLayer = new VectorLayer({
    style: styles.default,
    zIndex: 1
  });

  const map = new Map({
    layers: [
      new TileLayer({
        source: new OSM()
      }),
      vectorLayer,
      centerLayer
    ],
    controls: [new ScaleLine()],
    interactions: defaults({
      dragPan: false,
      doubleClickZoom: false,
      shiftDragZoom: false,
      mouseWheelZoom: false
    }),
    view: new View({
      center: fromLonLat([parseFloat(props.value.longitude), parseFloat(props.value.latitude)]),
      zoom: 18
    })
  })

  const mapRef = useCallback(node => {
    if (node !== null) {
      map.setTarget(node)
    }
  }, [])

  useEffect(() => {
    // Selectable marker
    const select = new Select({ style: styles.selected })

    map.addInteraction(select);

    select.on('select', function (e) {
      feature.setStyle(styles.default);
      centerLayer.setZIndex(0);

      if (e.selected.length != 0) {

        if (e.selected[0].getGeometry() == feature.getGeometry()) {
          if (e.selected[0].style_.image_.fill_.color_ != '#da2f36') {
            feature.setStyle(styles.selected);
            centerLayer.setZIndex(2);
            e.preventDefault()
            return false
          }
        }
        let data = _.assign({}, e.selected[0].getProperties(), { geometry: undefined });

        props.onSelectMarker(props.index, data)
      } else {
        props.onUnselectMarker(props.index)
      }
    })
  }, [])

  useEffect(() => {
    if (olMap.isOpened) {
      const path = new Path('/referentials/:referentialId')
      const { referentialId } = path.partialTest(location.pathname)
      const url = `${path.build({ referentialId })}/autocomplete_stop_areas/${props.value.stoparea_id}/around?target_type=zdep`

      fetch(url)
        .then(res => res.json())
        .then(data => {
          const features = geoJSON.readFeatures(data)
          vectorLayer.setSource(
            new VectorSource({ features })
          )
        })
    }
  }, [olMap.isOpened])

  if (!olMap.isOpened) return false

  return (
    <div className='map_container'>
      <div className='map_metas'>
        <p>
          <strong>{olMap.json.name}</strong>
        </p>
        <p>
          <strong>{I18n.t('routes.edit.map.stop_point_type')} : </strong>
          {olMap.json.area_type}
        </p>
        <p>
          <strong>{I18n.t('routes.edit.map.short_name')} : </strong>
          {olMap.json.short_name}
        </p>
        <p>
          <strong>{I18n.t('id_reflex')} : </strong>
          {olMap.json.user_objectid}
        </p>

        <p><strong>{I18n.t('routes.edit.map.coordinates')} : </strong></p>
        <p style={{ paddingLeft: 10, marginTop: 0 }}>
          <em>{I18n.t('routes.edit.map.proj')}.: </em>WSG84<br />
          <em>{I18n.t('routes.edit.map.lat')}.: </em>{olMap.json.latitude} <br />
          <em>{I18n.t('routes.edit.map.lon')}.: </em>{olMap.json.longitude}
        </p>
        <p>
          <strong>{I18n.t('routes.edit.map.postal_code')} : </strong>
          {olMap.json.zip_code}
        </p>
        <p>
          <strong>{I18n.t('routes.edit.map.city')} : </strong>
          {olMap.json.city_name}
        </p>
        <p>
          <strong>{I18n.t('routes.edit.map.comment')} : </strong>
          {olMap.json.comment}
        </p>
        {(props.value.stoparea_id != olMap.json.stoparea_id) && (
          <div className='btn btn-primary btn-sm'
            onClick={() => { props.onUpdateViaOlMap(props.index, olMap.json) }}
          >{I18n.t('actions.select')}</div>
        )}
      </div>
      <div className='map_content'>
        <div ref={mapRef} className='map'></div>
      </div>
    </div>
  )
}

StopPointsMap.propTypes = {
}
