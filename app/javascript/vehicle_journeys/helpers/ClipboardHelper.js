import { chunk, isEmpty } from 'lodash'
import addMinutes from 'date-fns/addMinutes'
import { formatTime, parseTime } from './index'

const computeArrivalTime = (hour, minute, copyItem) => {
	// First we create a date from the values
	// then we update the date by adding the delta
	// finally return an string => `HH:mm`
	if (copyItem.isDummy) return '-'

	let date = parseTime({hour, minute})
	date = addMinutes(date, copyItem.delta)

	return formatTime(date)
}
class ClipboardHelper {
	constructor() {
		this.error = null
		this.content = {
			copy: new CopyContent(this),
			paste: new PasteContent(this)
		}
	}

	updateCopyContent(items, width) {
		this.content.copy.setContent(items, width)
	}

	updatePasteContent(content) {
		this.content.paste.setContent(content)
	}

	validatePasteContent(toggleArrivals) {
		return this.content.paste.validate(toggleArrivals)
	}
}
export class CopyContent {
	constructor(clipboard) {
		this.clipboard = clipboard
	}

	setContent(items, width) {
		this.content = chunk(items, width)
	}
		
	serialize(toggleArrivals) {
		return this.content.map(row => {
			return row.map(item => {
				const { arrival_time, departure_time, dummy } = item
				const out = []

				out.push(
					dummy ? '-' : formatTime(departure_time, dummy)
				)

				toggleArrivals && out.push(
					dummy ? '-' : formatTime(arrival_time)
				)
			
				return out.join('\t')
			}).join('\t')
		}
		).join('\n')
	}

	deserialize() {
		return this.content
	}
}
export class PasteContent {
	constructor(clipboard) {
		this.clipboard = clipboard
	}

	get copyContent() {
		return this.clipboard.content.copy
	}

	setContent(content) {
		this.content = content
	}

	serialize() {
		return this.content
	}

	deserialize(toggleArrivals) {
		const chunkSize = toggleArrivals ? 2 : 1

		return this.content.split('\n').map((r, i) => {
			const deserializedCopyContent = this.copyContent.deserialize()
			const copyRow = deserializedCopyContent[i]
			const patseRow = r.split('\t')

			let prevVJAS

			return chunk(patseRow, chunkSize).map((cells, j) => {
				/*
					cells can be an array with:
						- one value if toggleArrivals is false => ['06:55']
						- two values if toggleArrivals is true => ['06:55', '06:56']
				*/
				const copyItem = copyRow[j]
				const departure = cells[0]
				const [dHour, dMinute] = departure.split(':')
				const arrival = cells[1] || computeArrivalTime(dHour, dMinute, copyItem)				
				const [aHour, aMinute] = arrival.split(':')

				return {
					index: copyItem.index,
					vjIndex: copyItem.vjIndex,
					departure_time: { hour: dHour, minute: dMinute },
					arrival_time: { hour: aHour, minute: aMinute }
				}
			})
		})
	}

	validate(toggleArrivals) {
		this.clipboard.error = null
		const serializedContent = this.serialize(toggleArrivals)
		const formatRegex = new RegExp(/(\d{2}:\d{2}(\t|\n))+(\d{2}:\d{2})/)

		try {
			if (isEmpty(serializedContent)) {
				throw ('missing_content')
			}

			if (serializedContent.length != this.copyContent.serialize(toggleArrivals).length) {
				throw ('size_does_not_match')
			}

			// Add validation to check date formats
			// if (!formatRegex.test(serializedContent)) {
			// 	throw('wrong_time_format')
			// }

			return true
		} catch (error) {
			this.clipboard.error = error
			return false
		}
	}
}

export default new ClipboardHelper()
