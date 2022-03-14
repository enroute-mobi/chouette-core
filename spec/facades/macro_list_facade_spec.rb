describe MacroListFacade do

	let(:template) do
		template = Object.new
		allow(template).to receive(:action_name) { 'new' }
		allow(template).to receive(:render) { '' }

		template
	end

	describe '#form_basename' do
		it "should return macro_list" do
			expect(described_class.new(Macro::List.new, template).form_basename).to eq('macro_list')
		end
	end

	describe '#json_state' do
		context "when macro is not persisted" do
			it 'should return empty state' do
				macro_list = Macro::List.new
				facade = described_class.new(macro_list, template)

				expected_json = JSON.generate({
					name: nil,
					comments: nil,
					macros: [],
					macro_contexts: [],
					is_show: false
				})

				expect(facade.json_state).to eq(expected_json)
			end
		end

		context 'when macro list has macros & contexts' do
			it 'should return a properly formed state' do
				macro_list = Macro::List.new(name: 'name', comments: 'comments')
				dummy_macro = Macro::Dummy.new(name: 'name', comments: 'comments', expected_result: 'warning')
				context = Macro::Context::TransportMode.new(transport_mode: 'bus')

				context.macros.push dummy_macro
				macro_list.macro_contexts.push context
				macro_list.macros.push dummy_macro

				facade = described_class.new(macro_list, template)

				expected_json = JSON.generate({
					name: 'name',
					comments: 'comments',
					macros: [{ id: nil, name: 'name', comments: 'comments', type: 'Macro::Dummy', errors: [], html: '', expected_result: 'warning' }],
					macro_contexts: [
						{
							id: nil,
							type: 'Macro::Context::TransportMode',
							macros: [{ id: nil, name: 'name', comments: 'comments', type: 'Macro::Dummy', errors: [], html: '', expected_result: 'warning' }],
							errors: [],
							html: '',
							transport_mode: 'bus'
						}
					],
					is_show: false
				})

				expect(facade.json_state).to eq(expected_json)
			end
		end
	end
end
