import Alpine from 'alpinejs'
import { isArray } from 'lodash'

import { MacroCollection } from '../../src/macro_lists/macro'
import { MacroContextCollection } from '../../src/macro_lists/macroContext'

Alpine.store('macroList', {
	isShow: false,
	macros: new MacroCollection(),
	macroContexts: new MacroContextCollection(),
	initState({ macros, macro_contexts }) {
		macros.forEach(macroAttributes => this.macros.add(macroAttributes))

		macro_contexts.forEach(({ macros, ...macroContextAttributes }) => {
			this.macroContexts.add(macroContextAttributes, macroContext => {
				if (isArray(macros)) {
					for (const macroAttributes of macros) {
						macroContext.macros.add(macroAttributes)
					}
				}
			})
		})
	}
})
