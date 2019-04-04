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
  const { origin, pathname } = window.location
  const url = `${origin}${pathname}.json`
  fetch(url)
  .then(res => {
    const json = res.json()
    json.then(mapGenerator)
  })
  .catch(e => console.error(e))
}

$(document).on('mapSourceLoaded', () => fecthStopArea(generateMap))