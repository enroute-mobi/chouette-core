describe OperationRunFacade do
	let(:workbench) { instance_double('Workbench', id: 1) }
	let(:macro_list_run) { instance_double('Macro::List::Run', id: 2, workbench: workbench) }
	let(:macro_run) { instance_double('Macro::Dummy::Run', id: 3) }
	let(:facade) { OperationRunFacade.new(macro_list_run)}

	describe '#message_table_params' do
		it 'should have 3 columns' do
			columns, options = facade.message_table_params
			expect(columns.length).to eq(2)
		end
	end

	# describe '#source_link' do
	# 	it 'should return an url pointing to the source object' do
	# 		line = FactoryBot.create(:line)
	# 		message = Macro::Message.new(source: line)

	# 		link = facade.source_link(message)
	# 		byebug
	# 	end
	# end
end
