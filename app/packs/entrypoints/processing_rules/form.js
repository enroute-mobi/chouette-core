import Alpine from 'alpinejs'

import ProcessableIdSelect from './form/processId.select'
import OperationStepSelect from './form/operationStep.select'

document.addEventListener('alpine:init', () => {
	Alpine.data('processingRuleForm', (initialState = {}) => ({
		isWorkgroupOwner: false,
		processableType: null,
		processableId: null,
		operationStep: null,
		...initialState,
		hasProcessableType() { return Boolean(this.processableType) },
		init() {
			this.processableIdSelect = new ProcessableIdSelect(this, 'processableIdSelect')
			this.operationStepSelect = new OperationStepSelect(this, 'operationStepSelect')

			this.$watch('processableType', () => {
				this.processableIdSelect.reload()
				this.operationStepSelect.reload()
			})
		},
	})
	)
})
