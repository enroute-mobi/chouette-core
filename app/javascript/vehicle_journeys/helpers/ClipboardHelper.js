import { chunk } from 'lodash'
import format from 'date-fns/format'

class ClipboardHelper {
	copy(items, width, toggleArrivals) {
		const contentTable = chunk(items, width)


		
		return contentTable.map(row => {
			const rowContent = row.map(cell => {
				const { arrival_time, departure_time, dummy } = cell
				const out = []

				out.push(this.format(arrival_time, dummy))
				toggleArrivals && out.push(this.format(departure_time, dummy))

				return out
			})
			return `${rowContent.join('\t')}\n`
		}
		).join('')

	}

	format(time, dummy) {
		if (dummy) return '-'

		return format(
			new Date(2000, 1, 1, time.hour, time.minute),
			'HH:mm'
		)
	}
}

export default new ClipboardHelper()
