class ConnectionLinksMap
  constructor: (@target)->

  prepare: ()->
    new Promise (resolve)=>
      $(document).on 'mapSourceLoaded', =>
        @initMap()
        @area = []
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
    stops = []

    if cLink.departure.longitude && cLink.departure.latitude
      firstStop = new ol.Feature({
        geometry: new ol.geom.Point(ol.proj.fromLonLat([parseFloat(cLink.departure.longitude), parseFloat(cLink.departure.latitude)]))
      })
      firstStop.setStyle(@defaultStyles(true))
      stops.push firstStop
      @area.push [parseFloat(cLink.departure.longitude), parseFloat(cLink.departure.latitude)]

    if cLink.arrival.longitude && cLink.arrival.latitude
      secondStop = new ol.Feature({
        geometry: new ol.geom.Point(ol.proj.fromLonLat([parseFloat(cLink.arrival.longitude), parseFloat(cLink.arrival.latitude)]))
      })
      secondStop.setStyle(@defaultStyles())
      stops.push secondStop
      @area.push [parseFloat(cLink.arrival.longitude), parseFloat(cLink.arrival.latitude)]

    vectorPtsLayer = new ol.layer.Vector({
      source: new ol.source.Vector({
        features: stops
      }),
      zIndex: 2
    })
    @map.addLayer vectorPtsLayer

  addStops: (stops)->
    geoColPts = []
    seenStopIds = [] = []

    stops.forEach (stop, i) =>
      if stop.longitude && stop.latitude
        unless seenStopIds.indexOf(stop.stoparea_id) > 0
          s = new ol.Feature({
            geometry: new ol.geom.Point(ol.proj.fromLonLat([parseFloat(stop.longitude), parseFloat(stop.latitude)]))
          })
          s.setStyle(@defaultStyles(if i==0 then true else false))
          geoColPts.push(s)
          @area.push [parseFloat(stop.longitude), parseFloat(stop.latitude)]
          seenStopIds.push stop.id

    vectorPtsLayer = new ol.layer.Vector({
      source: new ol.source.Vector({
        features: geoColPts
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

    if @area.length == 1
      @map.getView().setZoom(19)
      return

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
