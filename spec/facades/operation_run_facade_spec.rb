describe OperationRunFacade do
	let(:workbench) { instance_double('Workbench', id: 1) }
	let(:macro_list_run) { instance_double('Macro::List::Run', id: 2, workbench: workbench) }
	let(:macro_run) { instance_double('Macro::Dummy::Run', id: 3) }
	let(:facade) { OperationRunFacade.new(macro_list_run)}

	describe '#paginate_renderer_for' do
		it 'should return a link renderer for resource' do
			link_renderer = facade.paginate_renderer_for('macro', macro_run)

			expect(link_renderer).to be_an_instance_of(OperationRunFacade::PaginateLinkRenderer)
			expect(link_renderer.class.superclass).to eq(WillPaginate::ActionView::LinkRenderer)
			expect(link_renderer.url_params).to eq({ controller: 'macro_messages', action: 'index', workbench_id: 1, macro_list_run_id: 2, macro_run_id: 3})
		end
	end

	describe '#message_table_params' do
		it 'should have 3 columns' do
			columns, options = facade.message_table_params
			expect(columns.length).to eq(3)
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
