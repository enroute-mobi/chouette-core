import Alpine from 'alpinejs'
import { bindAll } from 'lodash'

import ProcessableIdSelect from './form/processId.select'
import OperationStepSelect from './form/operationStep.select'

class Store {
	constructor({
		workgroupRule = false,
		isWorkgroupOwner = false,
		processableType = null,
		processableId = null,
		operationStep = null,
		baseURL = ''
	} = {}) {
		this.workgroupRule = workgroupRule
		this.isWorkgroupOwner = isWorkgroupOwner
		this.processableType = processableType
		this.processableId = processableId
		this.operationStep = operationStep
		this.baseURL = baseURL

		bindAll(this, 'hasProcessableType')
	}

	hasProcessableType() { return Boolean(this.processableType)  }

	init() {
		this.processableIdSelect = new ProcessableIdSelect('processing_rule_processable_id', this)
		this.operationStepSelect = new OperationStepSelect('processing_rule_operation_step', this)
	
		this.$watch('processableType', () => {
			this.processableIdSelect.reload()
			this.operationStepSelect.reload()
		})
	}
}

Alpine.data('processingRuleForm', initialState => new Store(initialState))
