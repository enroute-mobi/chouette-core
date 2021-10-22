import { Icon, Style } from 'ol/style'

import BluePin from 'images/icons/map_pin_blue.png'
import OrangePin from 'images/icons/map_pin_orange.png'

const markers = {
	blue: BluePin,
	orange: OrangePin
}

export const connectionLinkStyle = color =>
	new Style({
		image: new Icon({
			anchor: [0.5, 1],
			anchorXUnits: 'fraction',
			anchorYUnits: 'fraction',
			src: markers[color]
		})
	})
