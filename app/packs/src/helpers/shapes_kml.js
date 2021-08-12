/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
class ShapesKml {
  constructor(target, url){
    this.target = target;
    this.url = url;
  }

  prepare(){
    return new Promise(resolve=> {
      this.initMap();
      this.area = [];
      this.seenStopIds = [];
      this.routes = {};
      return resolve(this);
    });
  }


  initMap() {
    const layer = new ol.layer.Tile({source: new ol.source.OSM()});
    // It appeared that the only way to style kml vector in OL3 is to add a new style directly instead of just referencing it : https://gis.stackexchange.com/questions/177804/unable-to-style-kml-layer-in-openlayers-3
    const vector = new ol.layer.Vector({
      source: new ol.source.Vector({
        url: this.url,
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
    });

    this.map = new ol.Map({
      target: this.target,
      layers:   [ layer, vector ],
      controls: [ new ol.control.ScaleLine(), new ol.control.Zoom(), new ol.control.ZoomSlider() ],
      interactions: ol.interaction.defaults({zoom: true}),
      view: new ol.View({
          center: [ 876970.8463461736, 5859807.853963373 ],
          zoom: 10
        })
    });

    const vectorSource = vector.getSource();

    return vectorSource.once('change', () => {
      if (vectorSource.getState() === 'ready') {
        const extent = vectorSource.getExtent();
        return this.map.getView().fit(extent, this.map.getSize());
      }
    });
  }
}

export default ShapesKml;
