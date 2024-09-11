# frozen_string_literal: true

RSpec.describe MergesController, type: :controller do
  login_user

  let(:context) do
    Chouette.create do
      workgroup do
        workbench organisation: Organisation.find_by(code: 'first') do
          referential :referential1
          referential :referential2

          control_list :workgroup_control_list, name: 'Workgroup control list', shared: true
          control_list :workbench_control_list, name: 'Workbench control list'
          macro_list :workbench_macro_list, name: 'Workbench macro list'
          workbench_processing_rule control_list: :workbench_control_list, operation_step: 'before_merge'
          workbench_processing_rule macro_list: :workbench_macro_list, operation_step: 'before_merge'
        end

        workgroup_processing_rule control_list: :workgroup_control_list, operation_step: 'before_merge'
      end
    end
  end
  let(:workbench) { context.workbench }
  let(:referentials) { [context.referential(:referential1), context.referential(:referential2)] }
  let(:workgroup_control_list) { context.control_list(:workgroup_control_list) }
  let(:workbench_control_list) { context.control_list(:workbench_control_list) }
  let(:workbench_macro_list) { context.macro_list(:workbench_macro_list) }

  let(:merge) do
    workbench.merges.create!(referentials: referentials, creator: 'test').tap(&:merge!)
  end
  let(:merge_workgroup_control_list_run) do
    merge.processings.find { |p| p.processed.try(:original_control_list) == workgroup_control_list }.processed
  end
  let(:merge_workbench_control_list_run) do
    merge.processings.find { |p| p.processed.try(:original_control_list) == workbench_control_list }.processed
  end
  let(:merge_workbench_macro_list_run) do
    merge.processings.find { |p| p.processed.try(:original_macro_list) == workbench_macro_list }.processed
  end

  describe 'GET #show' do
    let(:request) { get :show, params: { workbench_id: workbench.id, id: merge.id } }

    it { expect { request }.not_to raise_error }

    context 'with views' do
      render_views

      it 'renders all controls and macros' do
        request
        expect(response.body).to include(workbench_control_list_run_path(workbench, merge_workgroup_control_list_run))
        expect(response.body).to include(workbench_control_list_run_path(workbench, merge_workbench_control_list_run))
        expect(response.body).to include(workbench_macro_list_run_path(workbench, merge_workbench_macro_list_run))
      end
    end

    context 'when processed are destroyed' do
      before do
        merge_workgroup_control_list_run.destroy
        merge_workbench_control_list_run.destroy
        merge_workbench_macro_list_run.destroy
      end

      it { expect { request }.not_to raise_error }
    end
  end
end
