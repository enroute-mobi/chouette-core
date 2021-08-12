import { isDate, isObject, isString,  } from 'lodash'
import format from 'date-fns/format'
import parse from 'date-fns/parse'
import isBefore from 'date-fns/isBefore'

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
	

export const passingTimeIsBefore = (nextStop, prevStop) =>
	isBefore(
		formatTime(nextStop.arrival_time),
		formatTime(prevStop.arrival_time)
	)

export const computeDayOffSet = (prevStop, stop) => {
	let dayOffSet = (stop.departure_day_offset || 0) + !!prevStop

	if (!!prevStop && passingTimeIsBefore(stop, prevStop)) {
		dayOffSet += 1
	}

	return {
		departure_day_offset: dayOffSet,
		arrival_day_offset: dayOffSet
	}
}
