import React from 'react'
import Select from 'react-select'
import { find } from 'lodash'

const options = [
	{ id: '', color: 'transparent' },
	{ id: '#9B9B9B', color: '#9B9B9B'},
	{ id: '#FFA070', color: '#FFA070'},
	{ id: '#C67300', color: '#C67300'},
	{ id: '#7F551B', color: '#7F551B'},
	{ id: '#41CCE3', color: '#41CCE3'},
	{ id: '#09B09C', color: '#09B09C'},
	{ id: '#3655D7', color: '#3655D7'},
	{ id: '#6321A0', color: '#6321A0'},
	{ id: '#E796C6', color: '#E796C6'},
	{ id: '#DD2DAA', color: '#DD2DAA'}
]

const widthStyle = base => ({ ...base, width: '20%' })
const colorStyle = (base, { data: { color } }) => ({ ...base, color })

const ColorSelect = ({ onUpdateColor, selectedColor }) => (
	<Select
		value={find(options, ['id', selectedColor])}
		isSearchable={false}
		isMulti={false}
		options={options}
		placeholder=''
		getOptionValue={({ id }) => id}
		getOptionLabel={({ color }) => color}
		formatOptionLabel={() => (
			<span className='fa fa-circle mr-xs' />
		)}
		onChange={(selectedItem, meta) => {
			meta.action == 'select-option' && onUpdateColor(selectedItem.id)
		}}
		styles={{
			control: widthStyle,
			menu: widthStyle,
			option: colorStyle,
			singleValue: colorStyle,
		}}
	/>
)

export default ColorSelect
