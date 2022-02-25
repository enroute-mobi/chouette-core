import { isArray } from 'lodash'

export const addMacros = macros => object => {
	isArray(macros) && macros.forEach(attributes => object.macros.add(attributes))
}

export const formDataSetter = formData => (parentName = '') => (object, index) => {
	const getName = key => `macro_list${parentName}[${object.inputSelector}][${index}][${key}]`

	for (const key in object.attributes) {
		formData.set(getName(key), object[key])
	}

	formData.set(getName('position'), index + 1)
}
