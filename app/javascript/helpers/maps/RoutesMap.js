import Map from './Map'
import LayersButton from './utilities/LayersButton'
import LayersControl from './utilities/LayersControl'

export default class RoutesMap extends Map {
  constructor(target) {
    super(target)
    this.area = []
    this.seenStopIds = []
    this.routes = {}
  }

  addRoutes(routes) {
    routes.map(route => this.addRoute(route))
  }

  addRoute(route) {
    const geoColPts = []
    const geoColLns = []
    route.active = true
    if (route.id) { this.routes[route.id] = route }
    const stops = route.stop_points || route
    const geoColEdges = [
      new ol.Feature({
        geometry: new ol.geom.Point(ol.proj.fromLonLat([parseFloat(stops[0].longitude), parseFloat(stops[0].latitude)]))
      }),
      new ol.Feature({
        geometry: new ol.geom.Point(ol.proj.fromLonLat([parseFloat(stops[stops.length - 1].longitude), parseFloat(stops[stops.length - 1].latitude)]))
      })
    ]

    let prevStop = null
    stops.forEach((stop, i) => {
      if (stop.longitude && stop.latitude) {
        if (prevStop) {
          geoColLns.push(new ol.Feature({
            geometry: new ol.geom.LineString([
              ol.proj.fromLonLat([parseFloat(prevStop.longitude), parseFloat(prevStop.latitude)]),
              ol.proj.fromLonLat([parseFloat(stop.longitude), parseFloat(stop.latitude)])
            ])
          })
          )
        }
        prevStop = stop

        geoColPts.push(new ol.Feature({
          geometry: new ol.geom.Point(ol.proj.fromLonLat([parseFloat(stop.longitude), parseFloat(stop.latitude)]))
        }))
        if (!(this.seenStopIds.indexOf(stop.stop_area_id) > 0)) {
          this.area.push([parseFloat(stop.longitude), parseFloat(stop.latitude)])
          return this.seenStopIds.push(stop.stop_area_id)
        }
      }
    })

    const vectorPtsLayer = new ol.layer.Vector({
      source: new ol.source.Vector({
        features: geoColPts
      }),
      style: this.defaultStyles(),
      zIndex: 2
    })
    if (route.id) { route.vectorPtsLayer = vectorPtsLayer }
    const vectorEdgesLayer = new ol.layer.Vector({
      source: new ol.source.Vector({
        features: geoColEdges
      }),
      style: this.edgeStyles(),
      zIndex: 3
    })
    if (route.id) { route.vectorEdgesLayer = vectorEdgesLayer }
    const vectorLnsLayer = new ol.layer.Vector({
      source: new ol.source.Vector({
        features: geoColLns
      }),
      style: [this.lineStyle()],
      zIndex: 1
    })
    if (route.id) { route.vectorLnsLayer = vectorLnsLayer }
    this.map.addLayer(vectorPtsLayer)
    this.map.addLayer(vectorEdgesLayer)
    this.map.addLayer(vectorLnsLayer)
  }

  addLabels(resourceName) {
    const menu = new LayersControl(this.routes, this, resourceName)
    this.map.addControl(menu)
    return this.map.addControl(new LayersButton({menu, resourceName}))
  }

  fitZoom() {
    let area = []
    let found = false
    Object.keys(this.routes).forEach(id=> {
      const route = this.routes[id]
      if (route.active) {
        found = true
        return route.stop_points.forEach((stop, i) => {
          return area.push([parseFloat(stop.longitude), parseFloat(stop.latitude)])
        })
      }
    })
    if (!found) area = this.area
    const boundaries = ol.extent.applyTransform(
      ol.extent.boundingExtent(area), ol.proj.getTransform('EPSG:4326', 'EPSG:3857')
    )
    this.map.getView().fit(boundaries, this.map.getSize())
    let tooCloseToBounds = false
    const mapBoundaries = this.map.getView().calculateExtent(this.map.getSize())
    const mapWidth = mapBoundaries[2] - mapBoundaries[0]
    const mapHeight = mapBoundaries[3] - mapBoundaries[1]
    const marginSize = 0.1
    const heightMargin = marginSize * mapHeight
    const widthMargin = marginSize * mapWidth
    tooCloseToBounds = tooCloseToBounds || ((boundaries[0] - mapBoundaries[0]) < widthMargin)
    tooCloseToBounds = tooCloseToBounds || ((mapBoundaries[2] - boundaries[2]) < widthMargin)
    tooCloseToBounds = tooCloseToBounds || ((boundaries[1] - mapBoundaries[1]) < heightMargin)
    tooCloseToBounds = tooCloseToBounds || ((mapBoundaries[3] - boundaries[3]) < heightMargin)
    if (tooCloseToBounds) {
      this.map.getView().setZoom(this.map.getView().getZoom() - 1)
    }
  }
}