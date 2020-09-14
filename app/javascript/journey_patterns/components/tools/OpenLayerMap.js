import ReactDOM from 'react-dom';
import React, { Component } from 'react'
import PropTypes from 'prop-types'
import _ from 'lodash'
import 'ol';


// //open layers and styles
// var ol = require('openlayers');
// require('openlayers/css/ol.css');

// class Map extends React.Component
export default class OpenLayerMap extends Component {

  constructor(props) {
    super(props);
    console.log("OpenLayerMap : constructor")
    console.log(this.props.url)
    // this.state = {
    //   map:nil,
    //   comments: []
    // };
  }


  componentDidMount() {
    console.log("OpenLayerMap : componentDidMount")

    // create feature layer and vector source
    var layer = new ol.layer.Tile({source: new ol.source.OSM()})

    var vector = new ol.layer.Vector({
      source: new ol.source.Vector({
        url: this.props.url,
        format: new ol.format.KML({
          extractStyles: false
        })
      }),
      style: [
        new ol.style.Style({
          stroke: new ol.style.Stroke({color: '#007fbb', width: 3})
        })
      ],
      zIndex: 9999
    });

    // create map object with feature layer
    var map = new ol.Map({
      target: this.refs.mapContainer,
      layers: [ layer, vector ],
      controls: [ new ol.control.ScaleLine(), new ol.control.Zoom(), new ol.control.ZoomSlider() ],
      interactions: ol.interaction.defaults({zoom: true}),
      view: new ol.View({
        center: [ 876970.8463461736, 5859807.853963373 ],
        zoom: 10
      })
    });

    // map.on('click', this.handleMapClick.bind(this));

    // save map and layer references to local state
    this.setState({
      map: map,
      vector: vector
    });

  }

  // pass new features from props into the OpenLayers layer object
  componentDidUpdate(prevProps, prevState) {
    console.log("OpenLayerMap : componentDidUpdate")

    // this.state.vector.setSource(
    //   new ol.source.Vector({
    //     url: this.props.url,
    //     format: new ol.format.KML({
    //       extractStyles: false
    //     })
    //   })
    //   // new ol.source.Vector({
    //   //   features: this.props.routes
    //   // })
    // );
  }
  //
  // handleMapClick(event) {
  //
  //   // create WKT writer
  //   var wktWriter = new ol.format.WKT();
  //
  //   // derive map coordinate (references map from Wrapper Component state)
  //   var clickedCoordinate = this.state.map.getCoordinateFromPixel(event.pixel);
  //
  //   // create Point geometry from clicked coordinate
  //   var clickedPointGeom = new ol.geom.Point( clickedCoordinate );
  //
  //   // write Point geometry to WKT with wktWriter
  //   var clickedPointWkt = wktWriter.writeGeometry( clickedPointGeom );
  //
  //   // place Flux Action call to notify Store map coordinate was clicked
  //   Actions.setRoutingCoord( clickedPointWkt );
  //
  // }

  render () {
    return (
      <div className='large_map mb-lg' ref="mapContainer"> </div>
    );
  }

}

// // module.exports = Map;
// OpenLayerMap.propTypes = {
//   url: PropTypes.func.isRequired,
//
// }
