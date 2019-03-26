import Map from './Map'

export default class StopAreaMap extends Map
  constructor: (target, stopArea) ->
    super(target)
    @stopArea = stopArea
    @area = [ 
      parseFloat(stopArea.longitude),
      parseFloat(stopArea.latitude)
    ]

  addStopArea: ->   
    geoCol = [
      new ol.Feature(
        geometry: new ol.geom.Point(ol.proj.fromLonLat(@area))
      )
    ]

    vectorPtsLayer = new ol.layer.Vector(
      source: new ol.source.Vector(
        features: geoCol
      )
      style: @defaultStyles()
      zIndex: 1
    )

    vectorEdgesLayer = new ol.layer.Vector(
      source: new ol.source.Vector(
        features: geoCol
      )
      style: @edgeStyles()
      zIndex: 2
    )

    Array.of(vectorEdgesLayer, vectorPtsLayer).forEach (layer) =>
      @stopArea[layer] = layer
      @map.addLayer layer

  fitZoom: ->
    boundaries = ol.extent.applyTransform(
      ol.extent.boundingExtent([@area]), ol.proj.getTransform('EPSG:4326', 'EPSG:3857')
    )

    @map.getView().fit(boundaries, @map.getSize())
    @map.getView().setZoom(@map.getView().getZoom() - 15)