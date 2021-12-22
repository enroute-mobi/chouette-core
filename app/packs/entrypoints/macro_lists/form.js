import Alpine from 'alpinejs'

Alpine.store('macroList', {
	selectedType: '',
	macros: [],
	actions: ['duplicate', 'send_to_top', 'move_up', 'move_down', 'send_to_bottom', 'delete', 'restore'],
	addMacro(attributes) {
		this.macros = [...this.macros, { ...attributes, isDeleted: false }]
	},
	setMacros(macros) {
		console.log('this', this)
		console.log('set macros', macros)
		macros.forEach(this.addMacro.bind(this))
	},
	duplicate(index) {

	},
	move_up(index) {
		if (index == 0) return

		this.swapMacro(index, index - 1)
	},
	move_down(index) {
		if (index + 1 == this.macros.length) return

		this.swapMacro(index, index + 1)
	},
	send_to_top(index) {
		this.macros = [
			this.macros[index],
			...this.macros.filter((_m, i) => i != index),
		]
	},
	send_to_bottom(index) {
		this.macros = [
			...this.macros.filter((_m, i) => i != index),
			this.macros[index]
		]
	},
	delete(index) {
		console.log('this', this)
		this.macros[index].isDeleted = true
	},
	restore(index) {
		this.macros[index].isDeleted = false
	},
	swapMacro(indexA, indexB) {
		[this.macros[indexA], this.macros[indexB]] = [this.macros[indexB], this.macros[indexA]]
	},
	inputName(position, name) { return `macro_list[macros_attributes][${position}][${name}]` },
})


Alpine.start()
