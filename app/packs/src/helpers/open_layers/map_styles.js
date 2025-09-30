// Styles for javascript map and not react maps
import { Circle, Fill, Icon, Stroke, Style } from 'ol/style'

// Import des icônes SVG
import stopAreaIcon from 'images/icons/map_stop_area.svg'
import parentIcon from 'images/icons/map_parent.svg'
import childrenIcon from 'images/icons/map_children.svg'
import siblingsIcon from 'images/icons/map_siblings.svg'
import referentIcon from 'images/icons/map_referent.svg'
import particularsIcon from 'images/icons/map_particulars.svg'
import otherParticularsIcon from 'images/icons/map_other_particulars.svg'

// Fonction utilitaire pour créer un style d'icône
const createIconStyle = (src) => {
  return new Style({
    image: new Icon({
      src: src,
      scale: 0.4,
      anchor: [0.5, 1]
    })
  })
}

// Styles exportés
export const stop_area_style = createIconStyle(stopAreaIcon)
export const parent_style = createIconStyle(parentIcon)
export const children_style = createIconStyle(childrenIcon)
export const siblings_style = createIconStyle(siblingsIcon)
export const referent_style = createIconStyle(referentIcon)
export const particulars_style = createIconStyle(particularsIcon)
export const other_particulars_style = createIconStyle(otherParticularsIcon)
export const connection_link_style = createIconStyle(stopAreaIcon)
import BluePin from 'images/icons/map_pin_blue.png'
import OrangePin from 'images/icons/map_pin_orange.png'

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
