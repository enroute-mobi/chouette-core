# frozen_string_literal: true

RSpec.shared_examples 'ProcessingRule common' do
  it { is_expected.to belong_to(:processable).required(false) }

  it { is_expected.to validate_presence_of(:processable_type) }
  it { is_expected.to validate_presence_of(:processable_id) }
  it { is_expected.to validate_presence_of(:operation_step) }

  it { is_expected.to allow_value(Cuckoo::DaysOfWeek.all).for(:scheduling_days) }
  it { is_expected.to allow_value(Cuckoo::DaysOfWeek.new(monday: true, tuesday: true)).for(:scheduling_days) }
  it { is_expected.not_to allow_value(Cuckoo::DaysOfWeek.none).for(:scheduling_days) }
end

RSpec.describe ProcessingRule::Workbench, type: :model do
  let(:workbench) { context.workbench(:workbench) }

  include_examples 'ProcessingRule common'

  it { is_expected.to belong_to(:workbench).required }

  it { is_expected.to enumerize(:processable_type).in('Macro::List', 'Control::List') }

  it { is_expected.to enumerize(:operation_step).in('after_import', 'before_merge', 'after_merge', 'scheduling') }

  it { is_expected.to enumerize(:scheduling_target).in('none', 'current').with_default('none') }

  it { is_expected.to_not allow_value('after_aggregate').for(:operation_step) }

  context 'using a Control List' do
    let(:control_list) { Chouette.create { control_list }.control_list }

    before { subject.processable = control_list }

    it { is_expected.to validate_presence_of(:control_list_id) }

    %w[after_import before_merge after_merge].each do |operation_step|
      it { is_expected.to allow_value(operation_step).for(:operation_step) }
    end

    context 'when #scheduling_target is "none"' do
      before { subject.scheduling_target = 'none' }

      it { is_expected.to allow_value('scheduling').for(:operation_step) }
    end

    context 'when #scheduling_target is "current"' do
      before { subject.scheduling_target = 'none' }

      it { is_expected.to allow_value('scheduling').for(:operation_step) }
    end
  end

  context 'using a Macro List' do
    let(:macro_list) { Chouette.create { macro_list }.macro_list }

    before { subject.processable = macro_list }

    it { is_expected.to validate_presence_of(:macro_list_id) }

    %w[after_import before_merge].each do |operation_step|
      it { is_expected.to allow_value(operation_step).for(:operation_step) }
    end

    %w[after_merge].each do |operation_step|
      it { is_expected.not_to allow_value(operation_step).for(:operation_step) }
    end

    context 'when #scheduling_target is "none"' do
      before { subject.scheduling_target = 'none' }

      it { is_expected.to allow_value('scheduling').for(:operation_step) }
    end

    context 'when #scheduling_target is "current"' do
      before { subject.scheduling_target = 'current' }

      it { is_expected.not_to allow_value('scheduling').for(:operation_step) }
    end
  end

  describe 'Operation step uniqueness validation' do
    let(:context) do
      operation_step = self.operation_step

      Chouette.create do
        workbench :workbench do
          control_list :first_control_list
          control_list :second_control_list

          workbench_processing_rule control_list: :first_control_list, operation_step: operation_step
        end
      end
    end
    let(:first_control_list) { context.control_list(:first_control_list) }
    let(:second_control_list) { context.control_list(:second_control_list) }

    %w[after_import scheduling].each do |operation_step|
      context 'when operation_step is after_import' do
        let(:operation_step) { operation_step }

        context 'when a processing rule is created with a processable that is used in another processing rule with the same operation step' do
          subject do
            workbench.processing_rules.build(
              operation_step: operation_step,
              processable: first_control_list
            )
          end

          it { is_expected.to be_invalid }
        end

        context 'when a processing rule is created with a new processable' do
          subject do
            workbench.processing_rules.build(
              operation_step: operation_step,
              processable: second_control_list
            )
          end

          it { is_expected.to be_valid }
        end
      end
    end

    context 'when operation_step is not after_import' do
      let(:operation_step) { 'before_merge' }

      context 'when a processing rule is created with a processable that is used in another processing rule with the same operation step' do
        subject do
          workbench.processing_rules.build(
            operation_step: operation_step,
            processable: first_control_list
          )
        end

        it { is_expected.to be_invalid }
      end

      context 'when a processing rule is created with a new processable' do
        subject do
          workbench.processing_rules.build(
            operation_step: operation_step,
            processable: second_control_list
          )
        end

        it { is_expected.to be_invalid }
      end
    end
  end

  describe '#no_tag_overlap' do
    let(:context) do
      Chouette.create do
        workbench :workbench do
          macro_list

          tag :tag1
          tag :tag2
          tag :tag3
        end
      end
    end

    context 'when required and excluded tags overlap' do
      subject do
        workbench.processing_rules.build(
          operation_step: 'after_import',
          processable: context.macro_list,
          required_tag_ids: [context.tag(:tag1).id, context.tag(:tag2).id],
          excluded_tag_ids: [context.tag(:tag1).id]
        )
      end

      it do
        expect(subject).to be_invalid

        I18n.with_locale(:en) do
          expect(subject.errors[:excluded_tag_ids]).to include('Required and excluded tags cannot overlap')
          expect(subject.errors[:required_tag_ids]).to include('Required and excluded tags cannot overlap')
        end
      end
    end

    context 'when required and excluded tags do not overlap' do
      subject do
        workbench.processing_rules.build(
          operation_step: 'after_import',
          processable: context.macro_list,
          required_tag_ids: [context.tag(:tag1).id, context.tag(:tag2).id],
          excluded_tag_ids: [context.tag(:tag3).id]
        )
      end

      it { expect(subject).to be_valid }
    end
  end

  describe '#scheduled_perform_args' do
    subject { processing_rule.scheduled_perform_args }

    let(:context) do
      Chouette.create do
        workbench :workbench do
          control_list :control_list
          workbench_processing_rule control_list: :control_list, operation_step: 'scheduling'
          referential
        end
      end
    end
    let(:processing_rule) { context.workbench_processing_rule }

    before { processing_rule.scheduling_target = scheduling_target }

    context 'when #scheduling_target is "none"' do
      let(:scheduling_target) { 'none' }

      it { is_expected.to eq([[workbench, nil]]) }
    end

    context 'when #scheduling_target is "current"' do
      let(:scheduling_target) { 'current' }

      context 'when workbench is not merged' do
        it { is_expected.to eq([]) }
      end

      context 'when workbench is merged' do
        let(:referential) { instance_double(Referential) }

        before { allow(workbench).to receive(:output).and_return(double(current: referential)) }

        it { is_expected.to eq([[workbench, referential]]) }
      end
    end
  end

  describe '#perform' do
    subject { processing_rule.perform(operation: operation, referential: referential, operation_workbench: workbench) }

    let(:workgroup) { context.workgroup }
    let(:referential) { context.referential }
    let(:operation) do
      Import::Gtfs.create!(
        workbench: workbench,
        local_file: file_fixture('google-sample-feed.zip').open,
        creator: 'test',
        name: 'test'
      )
    end

    context 'with macro list' do
      let(:context) do
        Chouette.create do
          code_space :code_space

          workbench :workbench do
            macro_list :macro_list do
              macro :macro_create_code,
                    type: 'Macro::CreateCode',
                    name: 'Create Code',
                    target_model: 'Route',
                    source_attribute: 'name',
                    target_code_space_id: :code_space
            end

            referential

            workbench_processing_rule operation_step: 'after_import', macro_list: :macro_list
          end
        end
      end
      let(:macro_list) { context.macro_list(:macro_list) }
      let(:macro_create_code) { context.macro(:macro_create_code) }
      let(:processing_rule) { context.workbench_processing_rule }

      it 'creates a processing with the correct attributes' do
        subject
        expect(processing_rule.processings.last).to(
          have_attributes(
            step: 'after',
            workgroup_id: be_nil,
            workbench_id: workbench.id,
            processed_type: 'Macro::List::Run',
            processed_id: be_present,
            operation_type: 'Import::Base',
            operation_id: operation.id
          )
        )
      end

      it 'associates the processing to a macro list run with the correct attributes' do
        subject
        expect(processing_rule.processings.last.processed).to be_a(Macro::List::Run)
        expect(operation.processings.last.processed).to have_attributes(original_macro_list_id: macro_list.id)
      end

      it 'executes the macro list run' do
        subject
        expect(processing_rule.processings.last.processed.user_status).to eq('successful')
      end
    end

    context 'with control list' do
      let(:context) do
        Chouette.create do
          workbench :workbench do
            control_list :control_list do
              control
            end

            referential

            workbench_processing_rule operation_step: 'after_import', control_list: :control_list
          end
        end
      end
      let(:control_list) { context.control_list(:control_list) }
      let(:processing_rule) { context.workbench_processing_rule }

      it 'creates a processing with the correct attributes' do
        subject
        expect(processing_rule.processings.last).to(
          have_attributes(
            step: 'after',
            workgroup_id: be_nil,
            workbench_id: workbench.id,
            processed_type: 'Control::List::Run',
            processed_id: be_present,
            operation_type: 'Import::Base',
            operation_id: operation.id
          )
        )
      end

      it 'associates the processing to a control list run with the correct attributes' do
        subject
        expect(processing_rule.processings.last.processed).to be_a(Control::List::Run)
        expect(processing_rule.processings.last.processed).to have_attributes(original_control_list_id: control_list.id)
      end

      it 'executes the control list run' do
        subject
        expect(processing_rule.processings.last.processed.user_status).to eq('successful')
      end

      context 'without operation (scheduling)' do
        let(:operation) { nil }

        it 'creates a processing with the correct attributes' do
          subject
          expect(processing_rule.processings.last).to(
            have_attributes(
              step: 'after',
              workgroup_id: be_nil,
              workbench_id: workbench.id,
              processed_type: 'Control::List::Run',
              processed_id: be_present,
              operation_type: nil,
              operation_id: nil
            )
          )
        end

        it 'associates the processing to a control list run with the correct attributes' do
          subject
          expect(processing_rule.processings.last.processed).to be_a(Control::List::Run)
          expect(processing_rule.processings.last.processed).to have_attributes(original_control_list_id: control_list.id)
        end

        it 'executes the control list run' do
          subject
          expect(processing_rule.processings.last.processed.user_status).to eq('successful')
        end

        context 'with notification rule' do
          before do
            workbench.notification_rules.create!(
              notification_type: 'scheduled_processing',
              target_type: 'external_email',
              external_email: 'user@does-not-exist.ex',
              operation_statuses: %w[successful]
            )
          end

          it 'sends notification' do
            expect(ControlListRunMailer).to receive(:finished).and_return(double(deliver_later: nil))
            subject
          end
        end
      end
    end
  end
end

RSpec.describe ProcessingRule::Workgroup, type: :model do
  let(:workbench) { context.workbench(:workbench) }

  include_examples 'ProcessingRule common'

  it { is_expected.to belong_to(:workgroup).required }

  it { is_expected.to enumerize(:processable_type).in('Control::List', 'Flamingo::ValidationSetup') }

  it do
    is_expected.to(
      enumerize(:operation_step).in('before_import', 'after_import', 'before_merge', 'after_merge', 'after_aggregate', 'scheduling')
    )
  end

  it { is_expected.to enumerize(:scheduling_target).in('none', 'current', 'merged').with_default('none') }

  context 'using a Control List' do
    let(:control_list) { Chouette.create { control_list shared: true }.control_list }

    before { subject.processable = control_list }

    it { is_expected.to validate_presence_of(:control_list_id) }

    %w[after_import before_merge after_merge after_aggregate].each do |operation_step|
      it { is_expected.to allow_value(operation_step).for(:operation_step) }
    end

    %w[before_import].each do |operation_step|
      it { is_expected.not_to allow_value(operation_step).for(:operation_step) }
    end

    context 'when #scheduling_target is "none"' do
      before { subject.scheduling_target = 'none' }

      it { is_expected.to allow_value('scheduling').for(:operation_step) }
    end

    context 'when #scheduling_target is "current"' do
      before { subject.scheduling_target = 'current' }

      it { is_expected.to allow_value('scheduling').for(:operation_step) }
    end
  end

  context 'using a flamingo validation setup' do
    let(:flamingo_validation_setup) { Chouette.create { flamingo_validation_setup }.flamingo_validation_setup }

    before { subject.processable = flamingo_validation_setup }

    %w[before_import].each do |operation_step|
      it { is_expected.to allow_value(operation_step).for(:operation_step) }
    end

    %w[after_import before_merge after_merge after_aggregate].each do |operation_step|
      it { is_expected.not_to allow_value(operation_step).for(:operation_step) }
    end

    context 'when #scheduling_target is "none"' do
      before { subject.scheduling_target = 'none' }

      it { is_expected.not_to allow_value('scheduling').for(:operation_step) }
    end

    context 'when #scheduling_target is "current"' do
      before { subject.scheduling_target = 'current' }

      it { is_expected.not_to allow_value('scheduling').for(:operation_step) }
    end
  end

  describe 'Operation step uniqueness validation' do
    let(:context) do
      operation_step = self.operation_step

      Chouette.create do
        workgroup do
          workbench :workbench do
            control_list :first_control_list, shared: true
            control_list :second_control_list, shared: true
          end

          workgroup_processing_rule control_list: :first_control_list, operation_step: operation_step
        end
      end
    end
    let(:workgroup) { context.workgroup }
    let(:first_control_list) { context.control_list(:first_control_list) }
    let(:second_control_list) { context.control_list(:second_control_list) }

    %w[after_import scheduling].each do |operation_step|
      context 'when operation_step is after_import' do
        let(:operation_step) { operation_step }

        context 'when a processing rule is created with a processable that is used in another processing rule with the same operation step' do
          subject do
            workgroup.processing_rules.build(
              operation_step: operation_step,
              processable: first_control_list
            )
          end

          it { is_expected.to be_invalid }
        end

        context 'when a processing rule is created with a new processable' do
          subject do
            workgroup.processing_rules.build(
              operation_step: operation_step,
              processable: second_control_list
            )
          end

          it { is_expected.to be_valid }
        end
      end
    end

    context 'when operation_step is not after_import' do
      let(:operation_step) { 'before_merge' }

      context 'when a processing rule is created with a processable that is used in another processing rule with the same operation step' do
        subject do
          workgroup.processing_rules.build(
            operation_step: operation_step,
            processable: first_control_list
          )
        end

        it { is_expected.to be_invalid }
      end

      context 'when a processing rule is created with a new processable' do
        subject do
          workgroup.processing_rules.build(
            operation_step: operation_step,
            processable: second_control_list
          )
        end

        it { is_expected.to be_invalid }
      end
    end
  end

  context 'when target_workbench_ids and excluded_workbench_ids are both present' do
    before do
      subject.target_workbench_ids = [1]
      subject.excluded_workbench_ids = [1]
    end

    it { expect(subject).to_not be_valid }
  end

  describe '.accept_workbench' do
    subject { described_class.accept_workbench(workbench) }

    let(:context) do
      Chouette.create do
        workgroup do
          workbench :workbench do
            control_list :control_list, shared: true
          end
          workbench :other_workbench
          workgroup_processing_rule control_list: :control_list, operation_step: 'after_import'
        end
      end
    end
    let(:other_workbench) { context.workbench(:other_workbench) }
    let(:workgroup_processing_rule) { context.workgroup_processing_rule }

    before do
      workgroup_processing_rule.update(
        target_workbench_ids: target_workbench_ids,
        excluded_workbench_ids: excluded_workbench_ids
      )
    end

    context 'when taget and excluded workbenchs are empty' do
      let(:target_workbench_ids) { [] }
      let(:excluded_workbench_ids) { [] }

      it { expect(subject).to match_array [workgroup_processing_rule] }
    end

    context 'when taget contains workbench id and excluded is empty' do
      let(:target_workbench_ids) { [workbench.id] }
      let(:excluded_workbench_ids) { [] }

      it { expect(subject).to match_array [workgroup_processing_rule] }
    end

    context 'when taget contains other workbench id and excluded is empty' do
      let(:target_workbench_ids) { [other_workbench.id] }
      let(:excluded_workbench_ids) { [] }

      it { expect(subject).to be_empty }
    end

    context 'when taget is empty and excluded contains workbench id' do
      let(:target_workbench_ids) { [] }
      let(:excluded_workbench_ids) { [workbench.id] }

      it { expect(subject).to be_empty }
    end

    context 'when taget is empty and excluded contains other workbench id' do
      let(:target_workbench_ids) { [] }
      let(:excluded_workbench_ids) { [other_workbench.id] }

      it { expect(subject).to match_array [workgroup_processing_rule] }
    end
  end

  describe '#scheduled_perform_args' do
    subject { processing_rule.scheduled_perform_args }

    let(:context) do
      Chouette.create do
        organisation :owner_organisation
        organisation :other_organisation

        workgroup owner: :owner_organisation do
          workbench :owner_workbench, organisation: :owner_organisation do
            control_list :control_list, shared: true
          end
          workbench :other_workbench1, organisation: :other_organisation do
            referential :referential1
          end
          workbench :other_workbench2, organisation: :other_organisation do
            referential :referential2
          end
          workgroup_processing_rule control_list: :control_list, operation_step: 'scheduling'
        end
      end.tap do |context|
        context.referential(:referential1).update!(referential_suite: context.workbench(:other_workbench1).output)
        context.workbench(:other_workbench1).output.update!(current: context.referential(:referential1))
        context.referential(:referential2).update!(referential_suite: context.workbench(:other_workbench2).output)
        context.workbench(:other_workbench2).output.update!(current: context.referential(:referential2))
      end
    end
    let(:workgroup) { context.workgroup }
    let(:owner_workbench) { context.workbench(:owner_workbench) }
    let(:other_workbench1) { context.workbench(:other_workbench1) }
    let(:other_workbench2) { context.workbench(:other_workbench2) }
    let(:referential1) { context.referential(:referential1) }
    let(:referential2) { context.referential(:referential2) }
    let(:processing_rule) { context.workgroup_processing_rule }

    before { processing_rule.scheduling_target = scheduling_target }

    context 'when target is "none"' do
      let(:scheduling_target) { 'none' }

      it 'runs on owner workbench only' do
        is_expected.to eq([[owner_workbench, nil]])
      end
    end

    context 'when target is "current"' do
      let(:scheduling_target) { 'current' }

      context 'when workgroup is not aggregated' do
        it { is_expected.to eq([]) }
      end

      context 'when workgroup is aggregated' do
        let(:referential) { instance_double(Referential) }

        before { allow(workgroup).to receive(:output).and_return(double(current: referential)) }

        it { is_expected.to eq([[owner_workbench, referential]]) }
      end
    end

    context 'when target is "merged"' do
      let(:scheduling_target) { 'merged' }

      it 'returns all merged workbenches with their respective outputs' do
        is_expected.to match_array(
          [
            [other_workbench1, referential1],
            [other_workbench2, referential2]
          ]
        )
      end

      context 'with target workbenches' do
        before { processing_rule.update(target_workbench_ids: [other_workbench1.id]) }

        it 'returns only target workbenches' do
          is_expected.to match_array([[other_workbench1, referential1]])
        end
      end

      context 'with excluded workbenches' do
        before { processing_rule.update(excluded_workbench_ids: [other_workbench1.id]) }

        it 'returns everything except excluded_workbenches' do
          is_expected.to match_array([[other_workbench2, referential2]])
        end
      end
    end
  end

  describe '#perform' do
    subject { processing_rule.perform(operation: operation, referential: referential, operation_workbench: workbench) }

    let(:workgroup) { context.workgroup }
    let(:referential) { context.referential }
    let(:operation) do
      Import::Gtfs.create!(
        workbench: workbench,
        local_file: file_fixture('google-sample-feed.zip').open,
        creator: 'test',
        name: 'test'
      )
    end

    context 'with control list' do
      let(:context) do
        Chouette.create do
          workgroup do
            workbench :workbench do
              control_list :control_list, shared: true do
                control
              end

              referential
            end
          end

          workgroup_processing_rule operation_step: 'after_import', control_list: :control_list
        end
      end
      let(:control_list) { context.control_list(:control_list) }
      let(:processing_rule) { context.workgroup_processing_rule }

      it 'creates a processing with the correct attributes' do
        subject
        expect(processing_rule.processings.last).to(
          have_attributes(
            step: 'after',
            workgroup_id: workgroup.id,
            workbench_id: workbench.id,
            processed_type: 'Control::List::Run',
            processed_id: be_present,
            operation_type: 'Import::Base',
            operation_id: operation.id
          )
        )
      end

      it 'associates the processing to a control list run with the correct attributes' do
        subject
        expect(processing_rule.processings.last.processed).to be_a(Control::List::Run)
        expect(processing_rule.processings.last.processed).to have_attributes(original_control_list_id: control_list.id)
      end

      it 'executes the control list run' do
        subject
        expect(processing_rule.processings.last.processed.user_status).to eq('successful')
      end

      context 'without operation (scheduling)' do
        let(:operation) { nil }

        it 'creates a processing with the correct attributes' do
          subject
          expect(processing_rule.processings.last).to(
            have_attributes(
              step: 'after',
              workgroup_id: workgroup.id,
              workbench_id: workbench.id,
              processed_type: 'Control::List::Run',
              processed_id: be_present,
              operation_type: nil,
              operation_id: nil
            )
          )
        end

        it 'associates the processing to a control list run with the correct attributes' do
          subject
          expect(processing_rule.processings.last.processed).to be_a(Control::List::Run)
          expect(processing_rule.processings.last.processed).to have_attributes(original_control_list_id: control_list.id)
        end

        it 'executes the control list run' do
          subject
          expect(processing_rule.processings.last.processed.user_status).to eq('successful')
        end

        context 'with notification rule' do
          before do
            workbench.notification_rules.create!(
              notification_type: 'scheduled_processing',
              target_type: 'external_email',
              external_email: 'user@does-not-exist.ex',
              operation_statuses: %w[successful]
            )
          end

          it 'sends notification' do
            expect(ControlListRunMailer).to receive(:finished).and_return(double(deliver_later: nil))
            subject
          end
        end
      end
    end
  end
end

RSpec.describe ProcessingRule::Base::ScheduledJob do
  subject(:job) { described_class.new(processing_rule) }

  let(:workbench) { Chouette.create { workbench }.workbench }
  let(:scheduling_target) { 'none' }
  let(:processing_rule) { instance_double(ProcessingRule::Base, scheduling_target: scheduling_target) }

  let(:workbench1) { instance_double(Workbench) }
  let(:workbench2) { instance_double(Workbench) }
  let(:referential1) { instance_double(Referential) }
  let(:referential2) { instance_double(Referential) }

  before do
    allow(processing_rule).to receive(:scheduled_perform_args).and_return(
      [
        [workbench1, referential1],
        [workbench2, referential2]
      ]
    )
  end

  describe '#perform' do
    subject { job.perform }

    it 'performs the processing rule on each #scheduled_perform_args' do
      expect(processing_rule).to receive(:perform).with(
        operation_workbench: workbench1,
        referential: referential1
      )
      expect(processing_rule).to receive(:perform).with(
        operation_workbench: workbench2,
        referential: referential2
      )
      subject
    end
  end
end
