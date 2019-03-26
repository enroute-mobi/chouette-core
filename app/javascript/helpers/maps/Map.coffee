import LayersButton from './utilities/LayersButton'
import LayersControl from './utilities/LayersControl'

export default class Map
  constructor: (target) ->
    @target = target
    @area = []
    @seenStopIds = []
    @routes = {}

    @prepareGenerator = -> 
      @initMap()
      yield this
      @fitZoom()

  prepare: ->
    new Promise (resolve) =>
      resolve(@prepareGenerator())

  initMap: ->
    layer = window.mapBackgroundSource

    @map = new ol.Map(
      target: @target
      layers:   [ layer ]
      controls: [ new ol.control.ScaleLine(), new ol.control.Zoom(), new ol.control.ZoomSlider() ]
      interactions: ol.interaction.defaults({zoom: true})
      view: new ol.View()
    )

  lineStyle: (active=false) ->
    new ol.style.Style(
      stroke: new ol.style.Stroke(
        color: '#007fbb'
        width: active ? 3 : 0
      )
    )

  edgeStyles: (active=false) ->
    new ol.style.Style(
      image: new ol.style.Circle(
        radius: 5
        stroke: new ol.style.Stroke(
          color: '#007fbb'
          width: active ? 3 : 0
        )
        fill: new ol.style.Fill(
          color: '#007fbb'
          width: active ? 3 : 0
        )
      )
    )

  defaultStyles: (active=false) ->
    new ol.style.Style(
      image: new ol.style.Circle(
        radius: 4
        stroke: new ol.style.Stroke(
          color: '#007fbb'
          width: active ? 3 : 0
        )
        fill: new ol.style.Fill(
          color: '#ffffff'
          width: active ? 3 : 0
        )
      )
    )

  fitZoom: ->