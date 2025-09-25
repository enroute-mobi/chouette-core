// Styles for javacript map and not react maps
import { Circle, Fill, Icon, Stroke, Style } from 'ol/style'

import BluePin from 'images/icons/map_pin_blue.png'
import OrangePin from 'images/icons/map_pin_orange.png'

export const stop_area_style =
	new Style({
		image: new Icon({
			src: BluePin
		})
	})

export const parent_style =
	new Style({
		image: new Icon({
			src: OrangePin
		})
	})

export const children_style =
	new Style({
		image: new Icon({
			src: OrangePin
		})
	})

export const siblings_style =
	new Style({
		image: new Icon({
			src: OrangePin
		})
	})

export const referent_style =
	new Style({
		image: new Icon({
			src: OrangePin
		})
	})

export const particulars_style =
	new Style({
		image: new Icon({
			src: OrangePin
		})
	})

export const connection_link_style =
	new Style({
		image: new Icon({
			src: OrangePin
		})
	})

export const lineStyle = ([color, text_color]) => {
	const styles = [
		new Style({
			stroke: new Stroke({
				color: '#007fbb',
				width: 2
			})
		}),
		new Style({
			image: new Circle({
				radius: 5,
				stroke: new Stroke({
					color: '#007fbb',
					width: 0
				}),
				fill: new Fill({
					color: '#007fbb',
					width: 0
				})
			})
		}),
		new Style({
			image: new Circle({
				radius: 5,
				stroke: new Stroke({
					color: '#007fbb',
					width: 0
				}),
				fill: new Fill({
					color: '#007fbb',
					width: 0
				})
			})
		})
	]}
