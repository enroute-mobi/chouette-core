/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS201: Simplify complex destructure assignments
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
class ConnectionLinksMap {
  constructor(target){
    this.target = target;
  }

  prepare(){
    return new Promise(resolve=> {
      return $(document).on('mapSourceLoaded', () => {
        this.initMap();
        this.area = [];
        this.marker = null;
        return resolve(this);
      });
    });
  }

  initMap() {
    const layer = window.mapBackgroundSource;

    return this.map = new ol.Map({
      target: this.target,
      layers:   [ layer ],
      controls: [ new ol.control.ScaleLine(), new ol.control.Zoom(), new ol.control.ZoomSlider() ],
      interactions: ol.interaction.defaults({zoom: true}),
      view: new ol.View()
    });
  }

  addMarker(markerPath) {
    return this.marker = markerPath;
  }

  addConnectionLink(cLink){
    const stops = [];

    if (cLink.departure.longitude && cLink.departure.latitude) {
      const firstStop = new ol.Feature({
        geometry: new ol.geom.Point(ol.proj.fromLonLat([parseFloat(cLink.departure.longitude), parseFloat(cLink.departure.latitude)]))
      });
      firstStop.setStyle(this.defaultStyles(true));
      stops.push(firstStop);
      this.area.push([parseFloat(cLink.departure.longitude), parseFloat(cLink.departure.latitude)]);
    }

    if (cLink.arrival.longitude && cLink.arrival.latitude) {
      const secondStop = new ol.Feature({
        geometry: new ol.geom.Point(ol.proj.fromLonLat([parseFloat(cLink.arrival.longitude), parseFloat(cLink.arrival.latitude)]))
      });
      secondStop.setStyle(this.defaultStyles());
      stops.push(secondStop);
      this.area.push([parseFloat(cLink.arrival.longitude), parseFloat(cLink.arrival.latitude)]);
    }

    const vectorPtsLayer = new ol.layer.Vector({
      source: new ol.source.Vector({
        features: stops
      }),
      zIndex: 2
    });
    return this.map.addLayer(vectorPtsLayer);
  }

  addStops(stops){
    let ref;
    const geoColPts = [];
    const seenStopIds = (ref = [], ref);

    stops.forEach((stop, i) => {
      if (stop.longitude && stop.latitude) {
        if (!(seenStopIds.indexOf(stop.stoparea_id) > 0)) {
          const s = new ol.Feature({
            geometry: new ol.geom.Point(ol.proj.fromLonLat([parseFloat(stop.longitude), parseFloat(stop.latitude)]))
          });
          s.setStyle(this.defaultStyles(i===0 ? true : false));
          geoColPts.push(s);
          this.area.push([parseFloat(stop.longitude), parseFloat(stop.latitude)]);
          return seenStopIds.push(stop.id);
        }
      }
    });

    const vectorPtsLayer = new ol.layer.Vector({
      source: new ol.source.Vector({
        features: geoColPts
      }),
      zIndex: 2
    });
    return this.map.addLayer(vectorPtsLayer);
  }

  defaultStyles(first){
    if (first == null) { first = false; }
    return new ol.style.Style({
      image: new ol.style.Icon({
        anchor: [0.5, 1],
        anchorXUnits: 'fraction',
        anchorYUnits: 'fraction',
        src: first ? this.marker[0] : this.marker[1]})});
  }

  fitZoom(){
    const boundaries = ol.extent.applyTransform(
      ol.extent.boundingExtent(this.area), ol.proj.getTransform('EPSG:4326', 'EPSG:3857')
    );
    this.map.getView().fit(boundaries, this.map.getSize());

    if (this.area.length === 1) {
      this.map.getView().setZoom(19);
      return;
    }

    let tooCloseToBounds = false;
    const mapBoundaries = this.map.getView().calculateExtent(this.map.getSize());
    const mapWidth = mapBoundaries[2] - mapBoundaries[0];
    const mapHeight = mapBoundaries[3] - mapBoundaries[1];
    const marginSize = 0.1;
    const heightMargin = marginSize * mapHeight;
    const widthMargin = marginSize * mapWidth;
    tooCloseToBounds = tooCloseToBounds || ((boundaries[0] - mapBoundaries[0]) < widthMargin);
    tooCloseToBounds = tooCloseToBounds || ((mapBoundaries[2] - boundaries[2]) < widthMargin);
    tooCloseToBounds = tooCloseToBounds || ((boundaries[1] - mapBoundaries[1]) < heightMargin);
    tooCloseToBounds = tooCloseToBounds || ((mapBoundaries[3] - boundaries[3]) < heightMargin);
    if (tooCloseToBounds) {
      return this.map.getView().setZoom(this.map.getView().getZoom() - 1);
    }
  }
}

export default ConnectionLinksMap;
