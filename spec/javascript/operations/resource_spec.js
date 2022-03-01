import ResourceMixin from '../../../app/packs/src/operations/mixins/resource'

const Resource = ResourceMixin(class {})

describe('delete', () => {
	set('resource', () => new Resource)

	it('should set isDeleted to true', () => {
		resource.delete()

		expect(resource.isDeleted).toBeTruthy()
	})
})

describe('delete', () => {
	set('resource', () => new Resource)

	beforeEach(() => resource.delete())

	it('should set isDeleted to true', () => {
		resource.restore()

		expect(resource.isDeleted).toBeFalsy()
	})
})

describe('render', () => {
	set('html1', () => '<div>test1</div>')
	set('html2', () => '<div>test2</div>')
	set('html3', () => '<div>test3</div>')

	context('when resource.html is defined', () => {
		set('resource', () => new Resource({ html: html1, type: 'test' }))

		it('should return it', async () => {
			const result = await resource.render()

			expect(result).toEqual(html1)
		})
	})

	context('when resource.html is not defined', () => {
		set('resource', () => new Resource({ type: 'test' }))
	
		beforeEach(() => {
			resource.cacheHTML = html2
		})

		afterEach(() => {
			sessionStorage.clear()
		})

		it('should check the sessionStorage', async () => {
			const spy = jest.spyOn(resource, 'cacheHTML', 'get')
	
			const result = await resource.render()

			expect(spy).toHaveBeenCalledTimes(1)

			expect(result).toEqual(html2)
		})
	})

	context('when resource.html & sessionStorage does not contain html', () => {
		set('resource', () => new Resource({ type: 'test' }))

		beforeEach(() => {
			Object.defineProperty(resource, 'fecthedHTML', {
				value: jest.fn(() => html3)
			})
		})

		it('should fetch the html', async () => {
			const result = await resource.render()
			
			expect(result).toEqual(html3)
		})
	})
})
