import Alpine from 'alpinejs'
import FileRender from '../../src/documents/FileRender'

Alpine.data('filePreview', document => ({
	async init() {
		FileRender.call(this.$el, document)
	}
}))
