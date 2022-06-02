describe ControlListFacade do
	let(:context) { Chouette.create { workbench } }
	let(:workbench) { context.workbench }
	let(:control_list) { workbench.control_lists.build }
	let(:template) do
		template = Object.new
		allow(template).to receive(:action_name) { 'new' }
		allow(template).to receive(:render) { '' }

		template
	end
	let(:facade) { described_class.new(control_list, template) }

	describe '#form_basename' do
		subject { facade.form_basename }
		it { is_expected.to eq('control_list') }
	end

	describe '#json_state' do
		context "when control is not persisted" do
			it 'should return empty state' do
				expected_json = JSON.generate({
					name: nil,
					comments: nil,
					shared: false,
					controls: [],
					control_contexts: [],
					is_show: false
				})

				expect(facade.json_state).to eq(expected_json)
			end
		end

		context 'when control list has controls & contexts' do
			it 'should return a properly formed state' do
				control_list = workbench.control_lists.build(name: 'name', comments: 'comments', shared: false)
				dummy_control = Control::Dummy.new(name: 'name', criticity: 'warning', code: 'code', comments: 'comments', expected_result: 'warning')
				context = Control::Context::TransportMode.new(transport_mode: 'bus')

				context.controls.push dummy_control
				control_list.control_contexts.push context
				control_list.controls.push dummy_control

				allow(facade).to receive(:control_list) { control_list}

				expected_json = JSON.generate({
					name: 'name',
					comments: 'comments',
					shared: false,
					controls: [{ id: nil, name: 'name', comments: 'comments', criticity: 'warning', code: 'code', type: 'Control::Dummy', errors: [], html: '', expected_result: 'warning', target_model: 'Line' }],
					control_contexts: [
						{
							id: nil,
							type: 'Control::Context::TransportMode',
							controls: [{ id: nil, name: 'name', comments: 'comments', criticity: 'warning', code: 'code', type: 'Control::Dummy', errors: [], html: '', expected_result: 'warning', target_model: 'Line' }],
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
