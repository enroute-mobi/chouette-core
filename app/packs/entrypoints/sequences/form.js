import Alpine from 'alpinejs'
import { bindAll, uniq } from 'lodash'

class Store {
	constructor({
		sequence_type = '',
		static_list = null,
	} = {}) {
		this.sequence_type = sequence_type
		this.static_list = static_list || []

		bindAll(this, 'clipboardComponent')
	}

	clipboardComponent() {
		return {
			items: this.static_list,
			currentPage: 1,
			itemsPerPage: 15,

			pasteFromClipboard(event) {
				event.preventDefault();
				const clipboardData = event.clipboardData || window.clipboardData;
				const pastedData = clipboardData.getData('Text');
				this.addItems(pastedData);
			},

			addItems(data) {
				const newItems = data.split(/[\s,]+/)
					.map(item => item.trim())
					.filter(item => item && !this.items.includes(item));
				this.items = this.items.concat(newItems);
				this.static_list = this.items;
				this.currentPage = 1;
				this.updateTextArea();
			},

			removeItem(index) {
				const realIndex = index;
				this.items.splice(realIndex, 1);
				this.static_list = this.items;
				this.updateTextArea();

				if (this.paginatedItems.length === 0 && this.currentPage > 1) {
						this.currentPage--;
				}
			},

			updateItems(event) {
				const inputValue = event.target.value;
				const newItems = inputValue.split(/\n+/)
					.map(item => item.trim())
					.filter(item => item);
				this.items = Array.from(new Set(newItems));
				this.static_list = this.items;
				this.updateTextArea();
			},

			finalizeItems(event) {
				const inputValue = event.target.value;
				const newItems = inputValue.split(/[\s,]+/)
					.map(item => item.trim())
					.filter(item => item && !this.items.includes(item));
				this.items = this.items.concat(newItems);
				this.static_list = this.items;
				this.updateTextArea();
			},

			updateTextArea() {
				const textarea = document.querySelector('textarea[name="sequence[static_list]"]');
				if (textarea) {
					textarea.value = this.items.join('\n');
				}
			},

			// Pagination logic
			get paginatedItems() {
				const start = (this.currentPage - 1) * this.itemsPerPage;
				return this.items.slice(start, start + this.itemsPerPage);
			},

			get totalPages() {
				return Math.ceil(this.items.length / this.itemsPerPage);
			},

			prevPage() {
				if (this.currentPage > 1) {
					this.currentPage--;
				}
			},

			nextPage() {
				if (this.currentPage < this.totalPages) {
					this.currentPage++;
				}
			}
		}
	}
}

Alpine.data('sequenceForm', state => new Store(state))