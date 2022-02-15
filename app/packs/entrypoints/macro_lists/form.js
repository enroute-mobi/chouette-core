import Alpine from 'alpinejs'
import { MacroCollection } from '../../src/macro_lists/macro'
import { MacroContextCollection } from '../../src/macro_lists/macroContext'

window.Alpine = Alpine

Alpine.store('macroList', {
	isShow: false,
	macros: new MacroCollection(),
	macroContexts: new MacroContextCollection(),
	setMacros(macros) {
		macros.forEach(m => this.addMacro(m))
	},
	duplicate(macro) {
		this.addMacro(Macro.from(macro))
	}
})
