import { isUndefined } from 'lodash'
import format from 'date-fns/format'
import parse from 'date-fns/parse'
import isBefore from 'date-fns/isBefore'

const timeFormat = 'HH:mm'

export const formatTime = time => {
	if (time instanceof Date) {
		return format(time, timeFormat)
	}

	if (time instanceof Object) {
		return format(
			new Date(2000, 1, 1, time.hour, time.minute), timeFormat)
	}
}

export const parseTime = ({ hour, minute }) =>
	parse(`${hour}:${minute}`, timeFormat, new Date())

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
