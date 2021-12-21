import Alpine from 'alpinejs'

Alpine.store('macroList', {
	selectedType: '',
	macros: [],
	addMacro(attributes) {
		this.macros = [...this.macros, { ...attributes, isDeleted: false }]
	},
	setMacros(macros) {
		macros.forEach(this.addMacro.bind(this))
	},
	removeMacro(index) {
		this.macros[index].isDeleted = true
	},
	restoreMacro(index) {
		this.macros[index].isDeleted = false
	},
	swapMacro(indexA, indexB) {
		[this.macros[indexA], this.macros[indexB]] = [this.macros[indexB], this.macros[indexA]]
	},
	inputName(position, name) { return `macro_list[macros_attributes][${position}][${name}]` },
	moveUp(index) {
		if (index == 0) return

		this.swapMacro(index, index - 1)
	},
	moveDown(index) {
		if (index + 1 == this.macros.length) return

		this.swapMacro(index, index + 1)
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

