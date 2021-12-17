import Alpine from 'alpinejs'

Alpine.store('macroList', {
	selectedType: '',
	macros: [],
	addMacro(attributes) {
		this.macros = [...this.macros, attributes]
	},
	removeMacro(index) {
		const macro = this.macros[index]

		if (!!macro.id) {
			macro.isDeleted = true
		} else {
			this.macros = this.macros.filter((_m, i) => i != index)
		}
	},
	bindName(position, name) { return `macros_attributes[${position}][${name}]` },
	swap(indexA, indexB) {
		[this.macros[indexA], this.macros[indexB]] = [this.macros[indexB], this.macros[indexA]]
	},
	moveUp(index) {
		if (index == 0) return

		this.swap(index, index - 1)
	},
	moveDown(index) {
		if (index + 1 == this.macros.length) return

		this.swap(index, index + 1)
	},
	sendToTop(index) {
		this.macros = [
			this.macros[index],
			...this.macros.filter((_m, i) => i != index),
		]
	},
	sendToBottom(index) {
		this.macros = [
			...this.macros.filter((_m, i) => i != index),
			this.macros[index]
		]
	}
})

Alpine.start()
