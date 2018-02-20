import _ from 'lodash'
import React, { Component } from 'react'
import PropTypes from 'prop-types'

export default class OlMap extends Component{
  constructor(props, context){
    super(props, context)
  }

  fetchApiURL(id){
    const origin = window.location.origin
    const path = window.location.pathname.split('/', 3).join('/')
    return origin + path + "/autocomplete_stop_areas/" + id + "/around?target_type=zdep"
  }

  componentDidUpdate(prevProps, prevState){
    if(prevProps.value.olMap.isOpened == false && this.props.value.olMap.isOpened == true){
      var source = new ol.source.Vector({
        format: new ol.format.GeoJSON(),
        url: this.fetchApiURL(this.props.value.stoparea_id)
      })
      var feature = new ol.Feature({
        geometry: new ol.geom.Point(ol.proj.fromLonLat([parseFloat(this.props.value.longitude), parseFloat(this.props.value.latitude)]))
      })

      var defaultStyles = new ol.style.Style({
        image: new ol.style.Circle(({
          radius: 4,
          fill: new ol.style.Fill({
            color: '#004d87'
          })
        }))
      })
      var selectedStyles = new ol.style.Style({
        image: new ol.style.Circle(({
          radius: 6,
          fill: new ol.style.Fill({
            color: '#da2f36'
          })
        }))
      })

      var centerLayer = new ol.layer.Vector({
        source: new ol.source.Vector({
          features: [feature]
        }),
        style: selectedStyles,
        zIndex: 2
      })
      var vectorLayer = new ol.layer.Vector({
        source: source,
        style: defaultStyles,
        zIndex: 1
      });

      var map = new ol.Map({
        target: 'stoppoint_map' + this.props.index,
        layers: [
          new ol.layer.Tile({
            source: new ol.source.OSM()
          }),
          vectorLayer,
          centerLayer
        ],
        controls: [ new ol.control.ScaleLine() ],
        interactions: ol.interaction.defaults({
          dragPan: false,
          doubleClickZoom: false,
          shiftDragZoom: false,
          mouseWheelZoom: false
        }),
        view: new ol.View({
          center: ol.proj.fromLonLat([parseFloat(this.props.value.longitude), parseFloat(this.props.value.latitude)]),
          zoom: 18
        })
      });

      // Selectable marker
      var select = new ol.interaction.Select({
        style: selectedStyles
      });

      map.addInteraction(select);

      select.on('select', function(e) {
        feature.setStyle(defaultStyles);
        centerLayer.setZIndex(0);

        if(e.selected.length != 0) {

          if(e.selected[0].getGeometry() == feature.getGeometry()) {
            if(e.selected[0].style_.image_.fill_.color_ != '#da2f36'){
              feature.setStyle(selectedStyles);
              centerLayer.setZIndex(2);
              e.preventDefault()
              return false
            }
          }
          let data = _.assign({}, e.selected[0].getProperties(), {geometry: undefined});

          this.props.onSelectMarker(this.props.index, data)
        } else {
          this.props.onUnselectMarker(this.props.index)
        }
      }, this);
    }
  }

  render() {
    if (this.props.value.olMap.isOpened) {
      return (
        <div className='map_container'>
          <div className='map_metas'>
            <p>
              <strong>{this.props.value.olMap.json.name}</strong>
            </p>
            <p>
              <strong>{this.context.I18n.t('routes.edit.map.stop_point_type')} : </strong>
              {this.props.value.olMap.json.area_type}
            </p>
            <p>
              <strong>{this.context.I18n.t('routes.edit.map.short_name')} : </strong>
              {this.props.value.olMap.json.short_name}
            </p>
            <p>
              <strong>{this.context.I18n.t('id_reflex')} : </strong>
              {this.props.value.olMap.json.user_objectid}
            </p>

            <p><strong>{this.context.I18n.t('routes.edit.map.coordinates')} : </strong></p>
            <p style={{paddingLeft: 10, marginTop: 0}}>
              <em>{this.context.I18n.t('routes.edit.map.proj')}.: </em>WSG84<br/>
              <em>{this.context.I18n.t('routes.edit.map.lat')}.: </em>{this.props.value.olMap.json.latitude} <br/>
              <em>{this.context.I18n.t('routes.edit.map.lon')}.: </em>{this.props.value.olMap.json.longitude}
            </p>
            <p>
              <strong>{this.context.I18n.t('routes.edit.map.postal_code')} : </strong>
              {this.props.value.olMap.json.zip_code}
            </p>
            <p>
              <strong>{this.context.I18n.t('routes.edit.map.city')} : </strong>
              {this.props.value.olMap.json.city_name}
            </p>
            <p>
              <strong>{this.context.I18n.t('routes.edit.map.comment')} : </strong>
              {this.props.value.olMap.json.comment}
            </p>
            {(this.props.value.stoparea_id != this.props.value.olMap.json.stoparea_id) &&(
              <div className='btn btn-outline-primary btn-sm'
                onClick= {() => {this.props.onUpdateViaOlMap(this.props.index, this.props.value.olMap.json)}}
              >{this.context.I18n.t('actions.select')}</div>
            )}
          </div>
            <div className='map_content'>
              <div id={"stoppoint_map" + this.props.index} className='map'></div>
            </div>
        </div>
      )
    } else {
      return false
    }
  }
}

OlMap.propTypes = {
}

OlMap.contextTypes = {
  I18n: PropTypes.object
}
