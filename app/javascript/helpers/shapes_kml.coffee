class ShapesKml
  constructor: (@target, @url)->

  prepare: ()->
    new Promise (resolve)=>
      @initMap()
      @area = []
      @seenStopIds = []
      @routes = {}
      console.log("ShapesKml prepare solved !!")
      resolve(this)


  initMap: ->
    layer = new ol.layer.Tile({source: new ol.source.OSM()})
    # It appeared that the only way to style kml vector in OL3 is to add a new style directly instead of just referencing it : https://gis.stackexchange.com/questions/177804/unable-to-style-kml-layer-in-openlayers-3
    vector = new ol.layer.Vector({
      source: new ol.source.Vector({
        url: @url,
        format: new ol.format.KML({
          extractStyles: false
        })
      }),
      style: [
        new ol.style.Style({
            stroke: new ol.style.Stroke({color: '#007fbb', width: 3})
        })
      ],
      zIndex: 1
    })

    @map = new ol.Map
      target: @target,
      layers:   [ layer, vector ],
      controls: [ new ol.control.ScaleLine(), new ol.control.Zoom(), new ol.control.ZoomSlider() ],
      interactions: ol.interaction.defaults(zoom: true),
      view: new ol.View({
          center: [ 876970.8463461736, 5859807.853963373 ],
          zoom: 10
        })

    vectorSource = vector.getSource()

    vectorSource.once 'change', =>
      if (vectorSource.getState() == 'ready')
        extent = vectorSource.getExtent()
        @map.getView().fit extent, @map.getSize()

export default ShapesKml
