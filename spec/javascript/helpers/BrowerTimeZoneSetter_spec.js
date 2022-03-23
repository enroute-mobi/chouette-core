import cookie from 'cookie'
import BrowerTimeZoneSetter from '../../../app/packs/src/helpers/BrowerTimeZoneSetter'

const getCookies = () => cookie.parse(document.cookie)

describe('BrowerTimeZoneSetter', () => {
	beforeAll(() => {
		document.cookie = 'test=test'

		Intl.DateTimeFormat = jest.fn()
			.mockImplementationOnce(() => ({
				resolvedOptions: () => ({ timeZone: 'Paris' })
			}))
			.mockImplementationOnce(() => ({
				resolvedOptions: () => ({ timeZone: 'London' })
			}))
	})

	afterAll(() => {
		Intl.DateTimeFormat.mockRestore()
	})

	describe('#call', () => {
		it(`should set the 'browser.timezone' cookie`, () => {
			expect(getCookies()).toEqual({ test: 'test' })

			BrowerTimeZoneSetter.call()

			expect(getCookies()).toEqual({ test: 'test', 'browser.timezone': 'Paris' })

			BrowerTimeZoneSetter.call()

			expect(getCookies()).toEqual({ test: 'test', 'browser.timezone': 'London' })
		})
	})
})
		

