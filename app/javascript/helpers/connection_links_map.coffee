class ConnectionLinksMap
  constructor: (@target)->

  prepare: ()->
    new Promise (resolve)=>
      $(document).on 'mapSourceLoaded', =>
        @initMap()
        @area = []
        @cLink = null
        @marker = null
        resolve(this)

  initMap: ->
    layer = window.mapBackgroundSource

    @map = new ol.Map
      target: @target,
      layers:   [ layer ]
      controls: [ new ol.control.ScaleLine(), new ol.control.Zoom(), new ol.control.ZoomSlider() ],
      interactions: ol.interaction.defaults(zoom: true)
      view: new ol.View()

  addMarker: (markerPath) ->
    @marker = markerPath

  addConnectionLink: (cLink)->
    geoColPts = []

    if cLink.departure.longitude && cLink.departure.latitude
      firstStop = new ol.Feature({
        geometry: new ol.geom.Point(ol.proj.fromLonLat([parseFloat(cLink.departure.longitude), parseFloat(cLink.departure.latitude)]))
      })
      firstStop.setStyle(@defaultStyles(true))

    if cLink.arrival.longitude && cLink.arrival.latitude
      secondStop = new ol.Feature({
        geometry: new ol.geom.Point(ol.proj.fromLonLat([parseFloat(cLink.arrival.longitude), parseFloat(cLink.arrival.latitude)]))
      })
      secondStop.setStyle(@defaultStyles())

    @area = [
      [parseFloat(cLink.departure.longitude), parseFloat(cLink.departure.latitude)],
      [parseFloat(cLink.arrival.longitude), parseFloat(cLink.arrival.latitude)]
    ]

    vectorPtsLayer = new ol.layer.Vector({
      source: new ol.source.Vector({
        features: [firstStop, secondStop]
      }),
      zIndex: 2
    })
    @map.addLayer vectorPtsLayer

  defaultStyles: (first=false)->
    new ol.style.Style
      image: new ol.style.Icon
        anchor: [0.5, 1],
        anchorXUnits: 'fraction'
        anchorYUnits: 'fraction'
        src: if first then @marker[0] else @marker[1]

  fitZoom: ()->
    boundaries = ol.extent.applyTransform(
      ol.extent.boundingExtent(@area), ol.proj.getTransform('EPSG:4326', 'EPSG:3857')
    )
    @map.getView().fit boundaries, @map.getSize()
    tooCloseToBounds = false
    mapBoundaries = @map.getView().calculateExtent @map.getSize()
    mapWidth = mapBoundaries[2] - mapBoundaries[0]
    mapHeight = mapBoundaries[3] - mapBoundaries[1]
    marginSize = 0.1
    heightMargin = marginSize * mapHeight
    widthMargin = marginSize * mapWidth
    tooCloseToBounds = tooCloseToBounds || (boundaries[0] - mapBoundaries[0]) < widthMargin
    tooCloseToBounds = tooCloseToBounds || (mapBoundaries[2] - boundaries[2]) < widthMargin
    tooCloseToBounds = tooCloseToBounds || (boundaries[1] - mapBoundaries[1]) < heightMargin
    tooCloseToBounds = tooCloseToBounds || (mapBoundaries[3] - boundaries[3]) < heightMargin
    if tooCloseToBounds
      @map.getView().setZoom(@map.getView().getZoom() - 1)


export default ConnectionLinksMap
