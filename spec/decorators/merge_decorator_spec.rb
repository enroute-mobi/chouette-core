# frozen_string_literal: true

RSpec.describe MergeDecorator, type: %i[helper decorator] do
  let(:policy_context_class) { Policy::Context::Workbench }
  let(:current_referential) { create :workbench_referential, workbench: current_workbench }
  let(:object) { build_stubbed :merge, workbench: current_workbench, new: current_referential }
  let(:current_merge) { true }
  let(:context) { { workbench: current_workbench } }

  before(:each) do
    allow(object).to receive(:current?).and_return(current_merge)
    allow(object).to receive(:new_id).and_return(current_referential.id)
  end

  describe '#aggregated_at' do
    subject { decorator.aggregated_at }

    before(:each) do
      allow(object).to receive(:successful?).and_return(true)
    end

    context 'with no Aggregate' do
      it { is_expected.to be_nil }
    end

    context 'with a failed Aggregate' do
      before do
        create :aggregate, :failed, workgroup: current_workgroup, referential_ids: [current_referential.id]
      end

      it { is_expected.to be_nil }
    end

    context 'with a successful Aggregate on other referentials' do
      before do
        create :aggregate, :successful, ended_at: '2020/01/01 12:00', workgroup: current_workgroup, referential_ids: [create(:referential).id]
      end

      it { is_expected.to be_nil }
    end

    context 'with a successful Aggregate on right referentials' do
      let!(:aggregate) do
        create :aggregate, :successful, ended_at: '2020/01/01 12:00', workgroup: current_workgroup, referential_ids: [current_referential.id]
      end

      it 'should be present' do
        is_expected.to eq aggregate.ended_at
      end
    end

    context 'with 2 successfuls Aggregates on right referentials' do
      let!(:aggregate) do
        create :aggregate, :successful, ended_at: '2020/01/01 12:00', workgroup: current_workgroup, referential_ids: [current_referential.id]
      end
      let!(:aggregate2) do
        create :aggregate, :successful, ended_at: '2020/01/01 13:00', workgroup: current_workgroup, referential_ids: [current_referential.id]
      end

      it 'should be present' do
        is_expected.to eq aggregate2.ended_at
      end
    end
  end

  describe 'action links for' do
    context 'on show' do
      let(:action) { :show }

      it 'has corresponding actions' do
        expect_action_link_elements(action).to eq []
        expect_action_link_hrefs(action).to eq([])
      end

      context 'with a successful merge' do
        before(:each) do
          object.status = :successful
          object.new = create(:referential)
        end

        it 'has corresponding actions' do
          expect_action_link_elements(action).to eq [t('merges.actions.see_associated_offer')]
          expect_action_link_hrefs(action).to eq([workbench_referential_path(current_workbench, object.new)])
        end

        context 'with a non-current merge' do
          let(:current_merge) { false }

          it 'has corresponding actions' do
            expect_action_link_elements(action).to eq [t('merges.actions.see_associated_offer')]
            expect_action_link_hrefs(action).to eq([workbench_referential_path(current_workbench, object.new)])
          end

          context 'in the right organisation' do
            before(:each) do
              object.workbench.organisation = current_user.organisation
            end

            it 'has corresponding actions' do
              expect_action_link_elements(action).to eq [t('merges.actions.see_associated_offer')]
              expect_action_link_hrefs(action).to eq([workbench_referential_path(current_workbench, object.new)])
            end

            context 'with the rollback permission' do
              before(:each) do
                current_user.permissions = %w[merges.rollback]
              end

              it 'has corresponding actions' do
                expect_action_link_elements(action).to eq ['Revenir à cette offre', t('merges.actions.see_associated_offer')]
                expect_action_link_hrefs(action).to eq([rollback_workbench_merge_path(current_workbench, object), workbench_referential_path(current_workbench, object.new)])
              end
            end
          end
        end
      end
    end
  end
end
