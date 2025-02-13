# frozen_string_literal: true

RSpec.describe 'aggregates/show.html.slim', type: :view do
  let(:context) do
    Chouette.create do
      workgroup owner: Organisation.find_by(code: 'first') do
        workbench organisation: Organisation.find_by(code: 'first') do
          referential :referential1
          referential :referential2

          control_list :control_list, name: 'Control list', shared: true
        end

        workgroup_processing_rule control_list: :control_list, operation_step: 'after_aggregate'
      end
    end
  end
  let(:workgroup) { context.workgroup }
  let(:workbench) { context.workbench }
  let(:referentials) { [context.referential(:referential1), context.referential(:referential2)] }
  let(:control_list) { context.control_list(:control_list) }

  let(:aggregate) do
    Aggregate.create!(workgroup: workgroup, referentials: referentials, creator: 'test').tap(&:aggregate!)
  end
  let(:processing) { aggregate.processings.first }
  let(:control_list_run) do
    aggregate.processings.find { |p| p.processed.try(:original_control_list) == control_list }.processed
  end

  before do
    params.merge!(workgroup_id: workgroup.id.to_s, id: aggregate.id.to_s)
    assign :aggregate, aggregate.decorate(context: { workgroup: workgroup })
    assign :processing, processing
    assign :aggregate_resources, aggregate.resources.order(referential_created_at: :desc)
    # allow(view).to receive(:parent).and_return(workbench)
    # allow(view).to receive(:resource).and_return(workbench_import)
    allow(view).to receive(:resource_class).and_return(Aggregate)
    allow(view).to receive(:default_workbench).and_return(workbench)
  end

  it 'displays control list status and link to control list' do
    render
    expect(rendered).to include('text-success')
    expect(rendered).to include(workbench_control_list_run_path(workbench, control_list_run))
  end

  context 'when processed is destroyed' do
    before { control_list_run.destroy }

    it 'displays control list status but not link to control list' do
      render
      expect(rendered).to include('text-success')
      expect(rendered).not_to include(workbench_control_list_run_path(workbench, control_list_run))
    end
  end
end
