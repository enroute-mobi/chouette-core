/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
const RoutesLayersButton = function(options) {
  const {
    menu
  } = options;

  const toggleMenu = e=> {
    $(menu.element).toggleClass('hidden');
    return button.innerHTML = button.innerHTML === "+" ? "-" : "+";
  };

  var button = document.createElement("button");
  button.innerHTML = "+";
  button.addEventListener('click', toggleMenu, false);
  button.addEventListener('touchstart', toggleMenu, false);
  button.className = "ol-routes-layers-button";

  const element = document.createElement('div');
  element.className = 'ol-control ol-routes-layers-button-wrapper';

  element.appendChild(button);

  return ol.control.Control.call(this, {
    element,
    target: options.target
  });
};

ol.inherits(RoutesLayersButton, ol.control.Control);

const RoutesLayersControl = function(routes, routes_map) {

  const element = document.createElement('div');
  element.className = 'ol-unselectable ol-routes-layers hidden';
  Object.keys(routes).forEach(id=> {
    const route = routes[id];
    route.active = false;
    const label = document.createElement('a');
    label.title = route.name;
    label.className = '';
    label.innerHTML = route.name;
    element.appendChild(label);
    label.addEventListener("click", () => {
      route.active = !route.active;
      $(label).toggleClass("active");
      route.active;
      route.vectorPtsLayer.setStyle(routes_map.defaultStyles(route.active));
      route.vectorEdgesLayer.setStyle(routes_map.edgeStyles(route.active));
      route.vectorLnsLayer.setStyle(routes_map.lineStyle(route.active));
      return routes_map.fitZoom();
    });
    label.addEventListener("mouseenter", () => {
      route.vectorPtsLayer.setStyle(routes_map.defaultStyles(true));
      route.vectorEdgesLayer.setStyle(routes_map.edgeStyles(true));
      return route.vectorLnsLayer.setStyle(routes_map.lineStyle(true));
    });

    return label.addEventListener("mouseleave", () => {
      route.vectorPtsLayer.setStyle(routes_map.defaultStyles(route.active));
      route.vectorEdgesLayer.setStyle(routes_map.edgeStyles(route.active));
      return route.vectorLnsLayer.setStyle(routes_map.lineStyle(route.active));
    });
  });


  return ol.control.Control.call(this, {
    element
  });
};

ol.inherits(RoutesLayersControl, ol.control.Control);

class RoutesMap {
  constructor(target){
    this.target = target;
  }

  prepare(){
    return new Promise(resolve=> {
      return $(document).on('mapSourceLoaded', () => {
        this.initMap();
        this.area = [];
        this.seenStopIds = [];
        this.routes = {};
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

  addRoutes(routes){
    return Array.from(routes).map((route) =>
      this.addRoute(route));
  }

  addRoute(route){
    const geoColPts = [];
    const geoColLns = [];
    route.active = true;
    if (route.id) { this.routes[route.id] = route; }
    const stops = route.stops || route;
    const geoColEdges = [
      new ol.Feature({
        geometry: new ol.geom.Point(ol.proj.fromLonLat([parseFloat(stops[0].longitude), parseFloat(stops[0].latitude)]))
      }),
      new ol.Feature({
        geometry: new ol.geom.Point(ol.proj.fromLonLat([parseFloat(stops[stops.length - 1].longitude), parseFloat(stops[stops.length - 1].latitude)]))
      })
    ];

    let prevStop = null;
    stops.forEach((stop, i) => {
      if (stop.longitude && stop.latitude) {
        if (prevStop) {
          geoColLns.push(new ol.Feature({
            geometry: new ol.geom.LineString([
              ol.proj.fromLonLat([parseFloat(prevStop.longitude), parseFloat(prevStop.latitude)]),
              ol.proj.fromLonLat([parseFloat(stop.longitude), parseFloat(stop.latitude)])
            ])
          })
          );
        }
        prevStop = stop;

        geoColPts.push(new ol.Feature({
          geometry: new ol.geom.Point(ol.proj.fromLonLat([parseFloat(stop.longitude), parseFloat(stop.latitude)]))
        }));
        if (!(this.seenStopIds.indexOf(stop.stoparea_id) > 0)) {
          this.area.push([parseFloat(stop.longitude), parseFloat(stop.latitude)]);
          return this.seenStopIds.push(stop.stoparea_id);
        }
      }
    });

    const vectorPtsLayer = new ol.layer.Vector({
      source: new ol.source.Vector({
        features: geoColPts
      }),
      style: this.defaultStyles(),
      zIndex: 2
    });
    if (route.id) { route.vectorPtsLayer = vectorPtsLayer; }
    const vectorEdgesLayer = new ol.layer.Vector({
      source: new ol.source.Vector({
        features: geoColEdges
      }),
      style: this.edgeStyles(),
      zIndex: 3
    });
    if (route.id) { route.vectorEdgesLayer = vectorEdgesLayer; }
    const vectorLnsLayer = new ol.layer.Vector({
      source: new ol.source.Vector({
        features: geoColLns
      }),
      style: [this.lineStyle()],
      zIndex: 1
    });
    if (route.id) { route.vectorLnsLayer = vectorLnsLayer; }
    this.map.addLayer(vectorPtsLayer);
    this.map.addLayer(vectorEdgesLayer);
    return this.map.addLayer(vectorLnsLayer);
  }

  lineStyle(active){
    if (active == null) { active = false; }
    return new ol.style.Style({
      stroke: new ol.style.Stroke({
        color: '#007fbb',
        width: active ? 3 : 0
      })
    });
  }

  edgeStyles(active){
    if (active == null) { active = false; }
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
    });
  }

  defaultStyles(active){
    if (active == null) { active = false; }
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
    });
  }

  addRoutesLabels() {
    const menu = new RoutesLayersControl(this.routes, this);
    this.map.addControl(menu);
    return this.map.addControl(new RoutesLayersButton({menu}));
  }

  fitZoom(){
    let area = [];
    let found = false;
    Object.keys(this.routes).forEach(id=> {
      const route = this.routes[id];
      if (route.active) {
        found = true;
        return route.stops.forEach((stop, i) => {
          return area.push([parseFloat(stop.longitude), parseFloat(stop.latitude)]);
      });
      }
  });
    if (!found) { ({
      area
    } = this); }
    const boundaries = ol.extent.applyTransform(
      ol.extent.boundingExtent(area), ol.proj.getTransform('EPSG:4326', 'EPSG:3857')
    );
    this.map.getView().fit(boundaries, this.map.getSize());
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


export default RoutesMap;
