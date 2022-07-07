import Alpine from 'alpinejs'
import { bindAll } from 'lodash'

import ProcessableIdSelect from './form/processId.select'
import OperationStepSelect from './form/operationStep.select'

class Store {
	constructor({
		isWorkgroupOwner = false,
		processableType = null,
		processableId = null,
		operationStep = null,
		baseURL = ''
	} = {}) {
		this.isWorkgroupOwner = isWorkgroupOwner
		this.processableType = processableType
		this.processableId = processableId
		this.operationStep = operationStep
		this.baseURL = baseURL

		bindAll(this, 'hasProcessableType')
	}

	hasProcessableType() { return Boolean(this.processableType)  }

	init() {
		this.processableIdSelect = new ProcessableIdSelect(this, 'processing_rule_processable_id', this.baseURL)
		this.operationStepSelect = new OperationStepSelect(this, 'processing_rule_operation_step')
	
		this.$watch('processableType', () => {
			this.processableIdSelect.reload()
			this.operationStepSelect.reload()
		})
	}
}

Alpine.data('processingRuleForm', initialState => new Store(initialState))
