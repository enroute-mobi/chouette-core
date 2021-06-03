import { chunk, isEmpty, isEqual, isNaN, last, map } from 'lodash'
import subMinutes from 'date-fns/subMinutes'
import getMinutes from 'date-fns/getMinutes'
import getHours from 'date-fns/getHours'
import differenceInMinutes from 'date-fns/differenceInMinutes'
import { formatTime, parseTime } from './index'
import { is } from 'date-fns/locale'

const computeArrivalTime = (departure, copyItem) => {
	if (copyItem.isDummy) return parseTime('00:00')

	return subMinutes(departure, copyItem.delta)
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
		this.contentTable = chunk(items, width)
	}
		
	serialize(toggleArrivals) {
		return this.contentTable.map(row => {
			return row.map(item => {
				const { arrival_time, departure_time, dummy } = item
				const out = []

				toggleArrivals && out.push(
					dummy ? '00:00' : formatTime(arrival_time)
				)

				out.push(
					dummy ? '00:00' : formatTime(departure_time, dummy)
				)
			
				return out.join('\t')
			}).join('\t')
		}
		).join('\n')
	}

	deserialize(toggleArrivals) {
		return this.contentTable.map(row => {
			return row.reduce((result, item) => {
				const { arrival_time, departure_time } = item
		
				return [
					...result,
					...toggleArrivals ? [arrival_time] : [],
					departure_time
				]

			}, [])
		})
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
		return this.content.replaceAll('↵', '\n').trim()
	}

	get contentTable() {
		return this.serialize().split('\n').map(r => r.split(/\s+|\t/))
	}

	isDummy(content) {
		return content.trim() == '-'
	}

	deserialize(toggleArrivals) {
		const chunkSize = toggleArrivals ? 2 : 1

		return this.contentTable.map((row, i) => {
			const deserializedCopyContent = this.copyContent.contentTable
			const copyRow = deserializedCopyContent[i]

			return chunk(row, chunkSize).map((cells, j) => {
				/*
					cells can be an array with:
						- one value if toggleArrivals is false => ['06:55']
						- two values if toggleArrivals is true => ['06:55', '06:56']
				*/
				const copyItem = copyRow[j]
				const cellContent = this.isDummy(last(cells)) ? '00:00' : last(cells)
				const departure = parseTime(cellContent)
				const arrival = toggleArrivals ? parseTime(cells[0]) : computeArrivalTime(departure, copyItem)

				return {
					x: copyItem.x,
					y: copyItem.y,
					departure_time: {
						hour: getHours(departure),
						minute: getMinutes(departure)
					},
					arrival_time: {
						hour: getHours(arrival),
						minute: getMinutes(arrival)
					},
					delta: differenceInMinutes(departure, arrival)
				}
			})
		})
	}

	validate(toggleArrivals) {
		this.clipboard.error = null
		const deserializedContent = this.contentTable
		const deserializedCopyContent = this.copyContent.deserialize(toggleArrivals)

		try {
			if (isEmpty(deserializedContent)) {
				throw ('missing_content')
			}

			// compare sizes
			const sizeMatch = isEqual(
				map(deserializedContent, 'length'),
				map(deserializedCopyContent, 'length')
			)

			if (!sizeMatch) {
				throw ('size_does_not_match')
			}

			deserializedContent.forEach(row => {
				row.forEach(cell => {
					if (this.isDummy(cell)) return

					const [hour, minute] = cell.split(':')

					if (!isEqual(hour.length, 2) || !isEqual((minute || '').length, 2)) {
						throw ('wrong_time_format')
					}
					
					const date = parseTime({ hour, minute })

					if(isNaN(date.getTime())) {
						throw('wrong_time_format')
					}
				})
			})

			return true
		} catch (error) {
			this.clipboard.error = error
			return false
		}
	}
}

export default new ClipboardHelper()
