export default function LayersControl(collection, map, resourceName) {

  const element = document.createElement('div')
  element.className = `ol-unselectable ol-${resourceName}-layers hidden`
  Object.keys(collection).forEach(id => {
    const resource = collection[id]
    resource.active = false
    const label = document.createElement('a')
    label.title = resource.name
    label.className = ''
    label.innerHTML = resource.name
    element.appendChild(label)
    label.addEventListener("click", () => {
      resource.active = !resource.active
      $(label).toggleClass("active")
      resource.active
      resource.vectorPtsLayer.setStyle(map.defaultStyles(resource.active))
      resource.vectorEdgesLayer.setStyle(map.edgeStyles(resource.active))
      resource.vectorLnsLayer.setStyle(map.lineStyle(resource.active))
      return map.fitZoom()
    })
    label.addEventListener("mouseenter", () => {
      resource.vectorPtsLayer.setStyle(map.defaultStyles(true))
      resource.vectorEdgesLayer.setStyle(map.edgeStyles(true))
      return resource.vectorLnsLayer.setStyle(map.lineStyle(true))
    })

    return label.addEventListener("mouseleave", () => {
      resource.vectorPtsLayer.setStyle(map.defaultStyles(resource.active))
      resource.vectorEdgesLayer.setStyle(map.edgeStyles(resource.active))
      return resource.vectorLnsLayer.setStyle(map.lineStyle(resource.active))
    })
  })


  return ol.control.Control.call(this, {
    element
  })
}