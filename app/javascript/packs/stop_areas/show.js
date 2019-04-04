import '../../helpers/polyfills'

import StopAreaMap from '../../helpers/maps/StopAreaMap'

const updateeMap = handler => {
  const map = handler.next().value
  map.addStopArea()
  handler.next()
}

const generateMap = stopArea => {
  if (!!stopArea.longitude && !!stopArea.latitude) {
  new StopAreaMap('stop_area_map', stopArea).prepare()
    .then(updateeMap)
  }
}

const fecthStopArea = mapGenerator => {
  fetch(`${window.location.href}.json`).then(res => {
    const json = res.json()
    json.then(mapGenerator)
  })
}

$(document).on('mapSourceLoaded', () => fecthStopArea(generateMap))