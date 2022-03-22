import cookie from 'cookie'
import BrowerTimeZoneSetter from '../../../app/packs/src/helpers/BrowerTimeZoneSetter'

const getCookies = () => cookie.parse(document.cookie)

describe('BrowerTimeZoneSetter', () => {
	beforeAll(() => {
		document.cookie = 'test=test'

		Intl.DateTimeFormat = jest.fn(() => ({
			resolvedOptions: () => ({
				timeZone: 'London'
			})
		}))

		expect(getCookies()).toEqual({ test: 'test'})
	})

	afterAll(() => {
		Intl.DateTimeFormat.mockRestore()
	})

	describe('#call', () => {
		beforeEach(() => {})
		context('when cookie is not set', () => {
			it(`should set the 'browser.timezone' cookie`, () => {
				BrowerTimeZoneSetter.call()

				expect(getCookies()).toEqual({ test: 'test', 'browser.timezone': 'London' })
			})
		})
		})

		context('when cookie is set', () => {
			beforeEach(() => {
				document.cookie = 'browser.timezone=Paris'

				expect(getCookies()).toEqual({ test: 'test', 'browser.timezone': 'Paris' })
			})
		
			it(`should update the 'browser.timezone' cookie`, () => {
				BrowerTimeZoneSetter.call()

				expect(getCookies()).toEqual({ test: 'test', 'browser.timezone': 'London' })
			})
		})
})
		

