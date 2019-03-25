import Map from './Map'

import LayersButton from './utilities/LayersButton'
import LayersControl from './utilities/LayersControl'

ol.inherits(LayersControl, ol.control.Control)

export default class StopAreaMap extends Map {
  constructor(target, stopArea) {
    super(target)
    this.stopArea = stopArea
    this.area = [ 
      parseFloat(stopArea.longitude),
      parseFloat(stopArea.latitude)
    ]
  }

  addStopArea() {    
    const geoCol = [
      new ol.Feature({
        geometry: new ol.geom.Point(ol.proj.fromLonLat(this.area))
      })
    ]

    const vectorPtsLayer = new ol.layer.Vector({
      source: new ol.source.Vector({
        features: geoCol
      }),
      style: this.defaultStyles(),
      zIndex: 1
    })

    const vectorEdgesLayer = new ol.layer.Vector({
      source: new ol.source.Vector({
        features: geoCol
      }),
      style: this.edgeStyles(),
      zIndex: 2
    })

    Array.of(vectorEdgesLayer, vectorPtsLayer).forEach(layer => {
      this.stopArea[layer] = layer
      this.map.addLayer(layer)
    })
  }

  fitZoom(){
    const boundaries = ol.extent.applyTransform(
      ol.extent.boundingExtent([this.area]), ol.proj.getTransform('EPSG:4326', 'EPSG:3857')
    )

    this.map.getView().fit(boundaries, this.map.getSize())
    this.map.getView().setZoom(this.map.getView().getZoom() - 15)
  }
}