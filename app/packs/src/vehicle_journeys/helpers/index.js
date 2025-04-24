import { isDate, isObject, isString,  } from 'lodash'
import format from 'date-fns/format'
import parse from 'date-fns/parse'

const timeFormat = 'HH:mm'

export const formatTime = time => {
	if (isDate(time)) {
		return format(time, timeFormat)
	}

	if (isObject(time)) {
		return format(
			new Date(2000, 1, 1, time.hour, time.minute), timeFormat)
	}
}

export const parseTime = time => {
	if (isString(time)) {
		const match = time.match(/\d{2}:\d{2}/)
		return parse(match && match[0], timeFormat, new Date())
	}

	if (isObject(time)) {
		return parse(`${time.hour}:${time.minute}`, timeFormat, new Date())
	}
}
