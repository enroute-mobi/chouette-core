import { applyMiddleware } from 'redux'
import logger from 'redux-logger';
import { isDev } from './env'

export default function applyMiddlewareWrapper(...middlewares) {
	const list = [
		...isDev ? [logger] : [],
		...middlewares
	]

	return applyMiddleware(...list)
}
