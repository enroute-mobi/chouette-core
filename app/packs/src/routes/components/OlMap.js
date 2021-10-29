import _ from 'lodash'
import React from 'react'
import { Feature } from 'ol'
import { Point } from 'ol/geom'
import { Vector as VectorLayer } from 'ol/layer'
import { Vector as VectorSource } from 'ol/source'
import { Circle, Fill, Style } from 'ol/style'
import { Select } from 'ol/interaction'
import { fromLonLat } from 'ol/proj'

import MapWrapper from '../../components/MapWrapper'

import { Path } from 'path-parser'
import PropTypes from 'prop-types'

import geoJSON from '../../helpers/geoJSON'

const getStyles = () => ({
  default: new Style({
    image: new Circle(({
      radius: 4,
      fill: new Fill({ color: '#004d87' })
    }))
  }),
  selected: new Style({
    image: new Circle(({
      radius: 6,
      fill: new Fill({ color: '#da2f36' })
    }))
  })
})

const path = new Path('/referentials/:referentialId')
const { referentialId } = path.partialTest(location.pathname)

export default function StopPointsMap({ index, onSelectMarker, onUpdateViaOlMap, onUnselectMarker, value}) {
  const styles = getStyles()
  const { latitude, longitude, olMap, stoparea_id } = value

  const feature = new Feature({ geometry: new Point(fromLonLat([parseFloat(longitude), parseFloat(latitude)])) })

  const centerLayer = new VectorLayer({ style: styles.default })

  const onMapInit = async map => {  
    const fetchedFeatures = await (await fetch(`${path.build({ referentialId })}/autocomplete_stop_areas/${stoparea_id}/around?target_type=zdep`)).json()

    const centerSource = new VectorSource({ features: geoJSON.readFeatures(fetchedFeatures) })
    centerLayer.setSource(centerSource)

    map.getLayers().insertAt(1, centerLayer)

    map.getView().fit(centerSource.getExtent(), { padding: [100, 100, 100, 100] })

    // Selectable marker
    const select = new Select({ style: styles.selected })

    map.addInteraction(select);

    select.on('select', e => {
      feature.setStyle(styles.default)
      centerLayer.setZIndex(0)

      if (e.selected.length > 0) {
        const [selectedItem] = e.selected

        if (selectedItem.getGeometry() == feature.getGeometry()) {

          if (selectedItem.style_.image_.fill_.color_ != '#da2f36') {
            feature.setStyle(styles.selected)
            centerLayer.setZIndex(2)
            e.preventDefault()
            return false
          }
        }

        onSelectMarker(index, { ...selectedItem.getProperties(), geometry: undefined })
      } else {
        onUnselectMarker(index)
      }
    })
  }

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
        {(stoparea_id != olMap.json.stoparea_id) && (
          <div className='btn btn-primary btn-sm'
            onClick={() => { onUpdateViaOlMap(index, olMap.json) }}
          >{I18n.t('actions.select')}</div>
        )}
      </div>
      <div className='map_content stop-point-map'>
        <MapWrapper features={[feature]} onInit={onMapInit} style={styles.selected} />
      </div>
    </div>
  )
}

StopPointsMap.propTypes = {
}
