import Alpine from 'alpinejs'

class FileRender {
	constructor(container, contentType) {

		this.container = container
		this.contentType = contentType

		this.preview = {
			width: 500,
			height: 500
		}
	}

	call(url) {
		switch(this.contentType) {
			case 'application/pdf':
				return this.#renderPDF(url)
			case 'image/jpeg':
			case 'image/png':
				return this.#renderImage(url)
		}
	}

	async #renderPDF(url) {
		const file = await pdfjsLib.getDocument({ url }).promise
		const fileCover = await file.getPage(1)
		const viewport = fileCover.getViewport({ scale: 0.8 })
		
		// Canvas
		const canvas = document.createElement('canvas')
		canvas.width = this.preview.width
		canvas.height = this.preview.height
		const canvasContext = canvas.getContext('2d')
		this.container.append(canvas)

		fileCover.render({ canvasContext, viewport })
	}

	#renderImage(url) {
		const img = new Image(this.preview.width, this.preview.height)
		img.src = url
		this.container.append(img)
	}
}

Alpine.data('filePreview', ({ contentType, url }) => ({
	async init() {
		new FileRender(this.$el, contentType).call(url)
	}
}))
