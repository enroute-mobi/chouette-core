import Alpine from 'alpinejs'
import { bindAll } from 'lodash'

class Store {
	constructor({
		sequence_type = '',
		static_list = [],
	} = {}) {
		this.sequence_type = sequence_type
		this.static_list = static_list

		bindAll(this, 'clipboardComponent')
	}

	clipboardComponent() {
		return {
			items: this.static_list,
			currentPage: 1,
			itemsPerPage: 15, // Nombre d'éléments affichés par page

			pasteFromClipboard(event) {
				event.preventDefault();
				const clipboardData = event.clipboardData || window.clipboardData;
				const pastedData = clipboardData.getData('Text');
				this.addItems(pastedData);
				event.target.value = ''; // Vider la textarea après collage
			},

			addItems(data) {
				const newItems = data.split(/[\s,]+/)
					.map(item => item.trim())
					.filter(item => item && !this.items.includes(item));
				this.items = this.items.concat(newItems);
				this.static_list = this.items;
				this.currentPage = 1;
				this.updateHiddenField();
			},

			removeItem(index) {
				const realIndex = index + (this.currentPage - 1) * this.itemsPerPage;
				this.items.splice(realIndex, 1);
				this.static_list = this.items;
				this.updateHiddenField();
			},

			updateHiddenField() {
				document.querySelector('input[name="sequence[static_list]"]').value = this.items.join(',');
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
