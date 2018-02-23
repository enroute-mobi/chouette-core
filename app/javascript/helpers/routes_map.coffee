RoutesLayersButton = (options) ->
  menu = options.menu

  toggleMenu = (e)=>
    $(menu.element).toggleClass 'hidden'
    button.innerHTML = if button.innerHTML == "+" then "-" else "+"

  button = document.createElement("button")
  button.innerHTML = "+"
  button.addEventListener('click', toggleMenu, false)
  button.addEventListener('touchstart', toggleMenu, false)
  button.className = "ol-routes-layers-button"

  element = document.createElement('div');
  element.className = 'ol-control ol-routes-layers-button-wrapper';

  element.appendChild(button)

  ol.control.Control.call(this, {
    element
    target: options.target
  })

ol.inherits RoutesLayersButton, ol.control.Control

RoutesLayersControl = (routes, routes_map) ->

  element = document.createElement('div')
  element.className = 'ol-unselectable ol-routes-layers hidden'
  Object.keys(routes).forEach (id)=>
    route = routes[id]
    route.active = true
    label = document.createElement('div')
    label.className = 'active'
    label.innerHTML = route.name
    element.appendChild label
    label.addEventListener "click", =>
      route.active = !route.active
      $(label).toggleClass "active"
      route.active
      route.vectorPtsLayer.setStyle routes_map.defaultStyles(route.active)
      route.vectorEdgesLayer.setStyle routes_map.edgeStyles(route.active)
      route.vectorLnsLayer.setStyle routes_map.lineStyle(route.active)
      routes_map.fitZoom()
    label.addEventListener "mouseenter", =>
      route.vectorPtsLayer.setStyle routes_map.defaultStyles(true)
      route.vectorEdgesLayer.setStyle routes_map.edgeStyles(true)
      route.vectorLnsLayer.setStyle routes_map.lineStyle(true)

    label.addEventListener "mouseleave", =>
      route.vectorPtsLayer.setStyle routes_map.defaultStyles(route.active)
      route.vectorEdgesLayer.setStyle routes_map.edgeStyles(route.active)
      route.vectorLnsLayer.setStyle routes_map.lineStyle(route.active)


  ol.control.Control.call(this, {
    element
  })

ol.inherits RoutesLayersControl, ol.control.Control

class RoutesMap
  constructor: (@target)->
    @initMap()
    @area = []
    @seenStopIds = []
    @routes = {}

  initMap: ->
    @map = new ol.Map
      target: @target,
      layers:   [ new ol.layer.Tile(source: new ol.source.OSM()) ]
      controls: [ new ol.control.ScaleLine(), new ol.control.Zoom(), new ol.control.ZoomSlider() ],
      interactions: ol.interaction.defaults(zoom: true)
      view: new ol.View()

  addRoutes: (routes)->
    for route in routes
      @addRoute route

  addRoute: (route)->
    geoColPts = []
    geoColLns = []
    route.active = true
    @routes[route.id] = route if route.id
    stops = route.stops || route
    geoColEdges = [
      new ol.Feature({
        geometry: new ol.geom.Point(ol.proj.fromLonLat([parseFloat(stops[0].longitude), parseFloat(stops[0].latitude)]))
      }),
      new ol.Feature({
        geometry: new ol.geom.Point(ol.proj.fromLonLat([parseFloat(stops[stops.length - 1].longitude), parseFloat(stops[stops.length - 1].latitude)]))
      })
    ]

    prevStop = null
    stops.forEach (stop, i) =>
      if stop.longitude && stop.latitude
        if prevStop
          geoColLns.push new ol.Feature
            geometry: new ol.geom.LineString([
              ol.proj.fromLonLat([parseFloat(prevStop.longitude), parseFloat(prevStop.latitude)]),
              ol.proj.fromLonLat([parseFloat(stop.longitude), parseFloat(stop.latitude)])
            ])
        prevStop = stop

        geoColPts.push(new ol.Feature({
          geometry: new ol.geom.Point(ol.proj.fromLonLat([parseFloat(stop.longitude), parseFloat(stop.latitude)]))
        }))
        unless @seenStopIds.indexOf(stop.stoparea_id) > 0
          @area.push [parseFloat(stop.longitude), parseFloat(stop.latitude)]
          @seenStopIds.push stop.stoparea_id

    vectorPtsLayer = new ol.layer.Vector({
      source: new ol.source.Vector({
        features: geoColPts
      }),
      style: @defaultStyles(),
      zIndex: 2
    })
    route.vectorPtsLayer = vectorPtsLayer if route.id
    vectorEdgesLayer = new ol.layer.Vector({
      source: new ol.source.Vector({
        features: geoColEdges
      }),
      style: @edgeStyles(),
      zIndex: 3
    })
    route.vectorEdgesLayer = vectorEdgesLayer if route.id
    vectorLnsLayer = new ol.layer.Vector({
      source: new ol.source.Vector({
        features: geoColLns
      }),
      style: [@lineStyle()],
      zIndex: 1
    })
    route.vectorLnsLayer = vectorLnsLayer if route.id
    @map.addLayer vectorPtsLayer
    @map.addLayer vectorEdgesLayer
    @map.addLayer vectorLnsLayer

  lineStyle: (active=true)->
    new ol.style.Style
      stroke: new ol.style.Stroke
        color: '#007fbb'
        width: if active then 3 else 0

  edgeStyles: (active=true)->
    new ol.style.Style
      image: new ol.style.Circle
        radius: 5
        stroke: new ol.style.Stroke
          color: '#007fbb'
          width: if active then 3 else 0
        fill: new ol.style.Fill
          color: '#007fbb'
          width: if active then 3 else 0

  defaultStyles: (active=true)->
    new ol.style.Style
      image: new ol.style.Circle
        radius: 4
        stroke: new ol.style.Stroke
          color: '#007fbb'
          width: if active then 3 else 0
        fill: new ol.style.Fill
          color: '#ffffff'
          width: if active then 3 else 0

  addRoutesLabels: ->
    menu = new RoutesLayersControl(@routes, this)
    @map.addControl menu
    @map.addControl new RoutesLayersButton(menu: menu)

  fitZoom: ()->
    area = []
    found = false
    Object.keys(@routes).forEach (id)=>
      route = @routes[id]
      if route.active
        found = true
        route.stops.forEach (stop, i) =>
          area.push [parseFloat(stop.longitude), parseFloat(stop.latitude)]
    area = @area unless found
    boundaries = ol.extent.applyTransform(
      ol.extent.boundingExtent(area), ol.proj.getTransform('EPSG:4326', 'EPSG:3857')
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


export default RoutesMap
