RSpec.describe MergePolicy, type: :pundit_policy do

  let( :record ){ build_stubbed :merge }

  permissions :create? do
    it_behaves_like 'permitted policy outside referential', 'merges.create'
  end

  let(:current_merge){ false }

  before(:each){
    allow(record).to receive(:current?){ current_merge }
  }

  permissions :rollback? do
    context "when the workbench belongs to another organisation" do

      it "denies user" do
        expect_it.not_to permit(user_context, record)
      end

      context 'permission present → '  do
        before do
          add_permissions('merges.rollback', to_user: user)
        end

        it "denies user" do
          expect_it.not_to permit(user_context, record)
        end
      end
    end

    context "when the workbench belongs to the same organisation" do
      before do
        record.workbench.organisation = user.organisation
      end
      it "denies user" do
        expect_it.not_to permit(user_context, record)
      end

      context 'permission present → '  do
        before do
          add_permissions('merges.rollback', to_user: user)
        end

        it "denies user" do
          expect_it.not_to permit(user_context, record)
        end
      end
    end

    context "when the merge was successful" do
      before do
        record.status = :successful
      end

      context "when the workbench belongs to another organisation" do

        it "denies user" do
          expect_it.not_to permit(user_context, record)
        end

        context 'permission present → '  do
          before do
            add_permissions('merges.rollback', to_user: user)
          end

          it "denies user" do
            expect_it.not_to permit(user_context, record)
          end
        end
      end

      context "when the workbench belongs to the same organisation" do
        before do
          record.workbench.organisation = user.organisation
        end
        it "denies user" do
          expect_it.not_to permit(user_context, record)
        end

        context 'permission present → '  do
          before do
            add_permissions('merges.rollback', to_user: user)
          end

          it 'allows user' do
            expect_it.to permit(user_context, record)
          end
        end
      end

      context "when the merge is the current one" do
        let(:current_merge){ true }

        context "when the workbench belongs to another organisation" do

          it "denies user" do
            expect_it.not_to permit(user_context, record)
          end

          context 'permission present → '  do
            before do
              add_permissions('merges.rollback', to_user: user)
            end

            it "denies user" do
              expect_it.not_to permit(user_context, record)
            end
          end
        end

        context "when the workbench belongs to the same organisation" do
          before do
            record.workbench.organisation = user.organisation
          end
          it "denies user" do
            expect_it.not_to permit(user_context, record)
          end

          context 'permission present → '  do
            before do
              add_permissions('merges.rollback', to_user: user)
            end

            it "denies user" do
              expect_it.not_to permit(user_context, record)
            end
          end
        end
      end
    end
  end
end
