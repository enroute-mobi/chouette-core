import Alpine from 'alpinejs'
import { bindAll, uniq } from 'lodash'

class Store {
	constructor({
		sequence_type = '',
		static_list = null,
	} = {}) {
		this.sequence_type = sequence_type
		this.static_list = static_list

		bindAll(this, 'clipboardComponent')
	}

	clipboardComponent() {
		return {
			items: [],
			pasteFromClipboard(event) {
					event.preventDefault();
					const clipboardData = event.clipboardData || window.clipboardData;
					const pastedData = clipboardData.getData('Text');
					this.addItems(pastedData);
			},
			addItems(data) {
					const newItems = data.split(/[\s,]+/).map(item => item.trim()).filter(item => item && !this.items.includes(item));
					this.static_list = this.items.concat(newItems);
			},
			removeItem(index) {
					this.static_list.splice(index, 1);
					this.updateTextArea();
			},
			updateItems(event) {
				const inputValue = event.target.value;
				const newItems = inputValue.split(/\n+/).map(item => item.trim()).filter(item => item);
				this.static_list = Array.from(new Set(newItems)); // Remove duplicates
				this.updateTextArea();
			},
			finalizeItems(event) {
				const inputValue = event.target.value;
				const newItems = inputValue.split(/[\s,]+/).map(item => item.trim()).filter(item => item && !this.items.includes(item));
				this.static_list = this.items.concat(newItems);
				this.updateTextArea();
			},
			updateTextArea() {
				const textarea = document.querySelector('textarea[name="sequence[static_list]"]');
				textarea.value = this.static_list.join('\n');
			}
		}
	}
}

Alpine.data('sequenceForm', state => new Store(state))