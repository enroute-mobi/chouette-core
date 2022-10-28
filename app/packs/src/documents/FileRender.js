import PDFObject from 'pdfobject'
import { isNil } from 'lodash'

export class InvalidContainerError extends Error {}
export class InvalidDocumentError extends Error {}
export class ContentTypeNotSupportedError extends Error {}

export default class FileRender {
	static width = 500
	static height = 500

	static call(container, { contentType, url } = {}) {
		if (container?.constructor?.name !== 'HTMLDivElement') {
			throw new InvalidContainerError('container must be a HTMLDivElement')
		}

		if (isNil(url)) {
			throw new InvalidDocumentError('url must be provided')
		}

		const { width, height } = this

		switch (contentType) {
			case 'application/pdf':
				PDFObject.embed(url, container, { width: `${width}px`, height: `${height}px` })
				break
			case 'image/jpeg':
			case 'image/png':
				const img = new Image(width, height)
				img.src = url
				container.append(img)
				break
		}
	}
}
