import { isArray, isNil } from 'lodash'

export class FormDataUpdater {
	constructor(formData, inputBaseName) {
		this.formData = formData
		this.inputBaseName = inputBaseName

		this.clear()
	}

	call = (parentName = '') => (object, index) => {
		const getName = key => `${this.inputBaseName}${parentName}[${object.inputSelector}][${index}][${key}]`

		for (const key in object.attributes) {
			const value = object[key]
			this.formData.set(getName(key, parentName), isNil(value) ? '' : value)
		}

		this.formData.set(getName('position', parentName), index + 1)
	}

	clear() {
		const keys = ['utf8', 'authenticity_token']
		// We had some issues to keep store & form in sync. Especially during edit where we had conflicts between subforms.
		// As a solution we decided to compute manually the formData.
		for (const [key] of [...this.formData]) { !keys.includes(key) && this.formData.delete(key) } // Reset all macro related fields
	}
}

export const addResourceToCollection = collectionName => collection => object => {
	isArray(collection) && collection.forEach(attributes => object[collectionName].add(attributes))
}
