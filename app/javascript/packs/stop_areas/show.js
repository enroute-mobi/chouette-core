import '../../helpers/polyfills'

import clone from '../../helpers/clone'
import StopAreaMap from '../../helpers/maps/StopAreaMap'

let stopArea = clone(window, "stopArea", true)
stopArea = JSON.parse(decodeURIComponent(stopArea))

new StopAreaMap('stop_area_map', stopArea).prepare().then(generator => {
  const map = generator.next().value
  map.addStopArea()
  generator.next()
})
