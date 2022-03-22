import cookie from 'cookie'

export default class BrowerTimeZoneSetter {
	static call() {
		document.cookie = cookie.serialize(
			'browser.timezone',
			Intl.DateTimeFormat().resolvedOptions().timeZone
		)
	}
}
