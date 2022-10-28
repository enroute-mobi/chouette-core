import FileRender, { InvalidContainerError, InvalidDocumentError } from '../../../app/packs/src/documents/FileRender'

describe('FileRender', () => {
	describe('width', () => {
		it('should equal 500', () => {
			expect(FileRender.width).toEqual(500)
		})
	})

	describe('height', () => {
		it('should equal 500', () => {
			expect(FileRender.height).toEqual(500)
		})
	})

	describe('call', () => {
		describe('when container is not a NodeElement', () => {
			it('should throw a InvalidContainerError', () => {
				const invalidCalls = [
					() => FileRender.call(null, {}),
					() => FileRender.call(1, {})
				]

				invalidCalls.forEach(call => {
					expect(call).toThrowError(InvalidContainerError)
				})
			})
		})

		describe('when document is not valid', () => {
			it('should throw a InvalidDocumentError', () => {
				const container = document.createElement('div')

				const invalidCalls = [
					() => FileRender.call(container, {}),
					() => FileRender.call(container, { contentType: 'application/pdf' }),
				]

				invalidCalls.forEach(call => {
					expect(call).toThrowError(InvalidDocumentError)
				})
			})
		})

		describe('content type', () => {
			describe('when pdf', () => {
				it('should preview the pdf', () => {
					const container = document.createElement('div')

					FileRender.call(container, { contentType: 'application/pdf', url: '../../fixtures/sample_pdf.pdf'  })

					const preview = container.firstChild

					expect(preview).toBeInstanceOf(HTMLEmbedElement)
					expect(Array.from(preview.classList)).toEqual(expect.arrayContaining(['pdfobject']))
				})
			})
	
			describe('when png', () => {
				it('should preview the png', () => {
					const container = document.createElement('div')
					const url = '../../fixtures/sample_png.png'

					FileRender.call(container, { contentType: 'image/png', url })

					const preview = container.firstChild
					expect(preview).toBeInstanceOf(Image)
					expect(preview.width).toEqual(500)
					expect(preview.height).toEqual(500)
					expect(preview.src).toEqual(expect.stringMatching('sample_png.png'))
				})
			})
			describe('when jpeg', () => {
				it('should preview the jpeg', () => {
					const container = document.createElement('div')
					const url = '../../fixtures/sample_jpeg.jpeg'

					FileRender.call(container, { contentType: 'image/jpeg', url })

					const preview = container.firstChild

					expect(preview).toBeInstanceOf(Image)
					expect(preview.width).toEqual(500)
					expect(preview.height).toEqual(500)
					expect(preview.src).toEqual(expect.stringMatching('sample_jpeg.jpeg'))
				})
			})

			describe('when other', () => {
				it('should not preview', () => {
					const container = document.createElement('div')
					const url = '../../fixtures/users.json'

					FileRender.call(container, { contentType: 'application/json', url })

					const preview = container.firstChild

					expect(preview).toBeNull()
				})
			})

		})
	})
})
