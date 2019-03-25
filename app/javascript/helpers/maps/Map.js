import LayersButton from './utilities/LayersButton'
import LayersControl from './utilities/LayersControl'

export default class Map {
  constructor(target) {
    this.target = target
    this.area = []
    this.seenStopIds = []
    this.routes = {}

    this.prepareGenerator = function* () {
      this.initMap()
      yield this
      return this.fitZoom()
    }
  }

  prepare() {
    return new Promise(resolve => {
      resolve(this.prepareGenerator())
    })
  }

  initMap() {
    const layer = window.mapBackgroundSource

    return this.map = new ol.Map({
      target: this.target,
      layers:   [ layer ],
      controls: [ new ol.control.ScaleLine(), new ol.control.Zoom(), new ol.control.ZoomSlider() ],
      interactions: ol.interaction.defaults({zoom: true}),
      view: new ol.View()
    })
  }

  lineStyle(active){
    if (active == null) { active = false }
    return new ol.style.Style({
      stroke: new ol.style.Stroke({
        color: '#007fbb',
        width: active ? 3 : 0
      })
    })
  }

  edgeStyles(active){
    if (active == null) { active = false }
    return new ol.style.Style({
      image: new ol.style.Circle({
        radius: 5,
        stroke: new ol.style.Stroke({
          color: '#007fbb',
          width: active ? 3 : 0
        }),
        fill: new ol.style.Fill({
          color: '#007fbb',
          width: active ? 3 : 0
        })
      })
    })
  }

  defaultStyles(active){
    if (active == null) { active = false }
    return new ol.style.Style({
      image: new ol.style.Circle({
        radius: 4,
        stroke: new ol.style.Stroke({
          color: '#007fbb',
          width: active ? 3 : 0
        }),
        fill: new ol.style.Fill({
          color: '#ffffff',
          width: active ? 3 : 0
        })
      })
    })
  }

  fitZoom() {}
}