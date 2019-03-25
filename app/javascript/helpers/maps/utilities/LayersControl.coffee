LayersControl = (routes, routes_map) ->
  element = document.createElement('div')
  element.className = 'ol-unselectable ol-routes-layers hidden'
  Object.keys(routes).forEach (id)=>
    route = routes[id]
    route.active = false
    label = document.createElement('a')
    label.title = route.name
    label.className = ''
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

ol.inherits LayersControl, ol.control.Control

export default LayersControl
