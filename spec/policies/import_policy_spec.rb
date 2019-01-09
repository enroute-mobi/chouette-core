RSpec.describe ImportPolicy, type: :policy do

  let(:record) { create :import }
  before(:each) { user.organisation = create(:organisation) }

  context "when the workbench belongs to another organisation (other workgroup)" do
    permissions :index? do
      it "allows user" do
        expect_it.to permit(user_context, record)
      end
    end
    permissions :show? do
      it "denies user" do
        expect_it.not_to permit(user_context, record)
      end
    end
    permissions :create? do
      it "denies user" do
        expect_it.not_to permit(user_context, record)
      end
    end
    permissions :destroy? do
      it "denies user" do
        expect_it.not_to permit(user_context, record)
      end
    end
    permissions :edit? do
      it "denies user" do
        expect_it.not_to permit(user_context, record)
      end
    end
    permissions :new? do
      it "denies user" do
        expect_it.not_to permit(user_context, record)
      end
    end
    permissions :update? do
      it "denies user" do
        expect_it.not_to permit(user_context, record)
      end
    end
  end

  context "when the workbench belongs to another organisation (same workgroup)" do
    before do
      allow(user.workgroups).to receive(:pluck).with(:id).and_return [record.workbench.workgroup_id]
    end

    permissions :index? do
      it "allows user" do
        expect_it.to permit(user_context, record)
      end
    end
    permissions :show? do
      it "denies user" do
        expect_it.to permit(user_context, record)
      end
    end
    permissions :create? do
      it "denies user" do
        expect_it.not_to permit(user_context, record)
      end
    end
    permissions :destroy? do
      it "denies user" do
        expect_it.not_to permit(user_context, record)
      end
    end
    permissions :edit? do
      it "denies user" do
        expect_it.not_to permit(user_context, record)
      end
    end
    permissions :new? do
      it "denies user" do
        expect_it.not_to permit(user_context, record)
      end
    end
    permissions :update? do
      it "denies user" do
        expect_it.not_to permit(user_context, record)
      end
    end
  end

   context "when the workbench belongs to the same organisation" do
    before do
      user.organisation.workbenches << record.workbench
    end

    #
    #  Non Destructive
    #  ---------------

    context 'Non Destructive actions →' do
      permissions :index? do
        it "allows user" do
          expect_it.to permit(user_context, record)
        end
      end
      permissions :show? do
        it "allows user" do
          expect_it.to permit(user_context, record)
        end
      end
    end


    #
    #  Destructive
    #  -----------

    context 'Destructive actions →' do
      permissions :create? do
        it "denies user" do
          expect_it.not_to permit(user_context, record)
        end

        context 'permission present → '  do
          before do
            add_permissions('imports.create', to_user: user)
          end

          it "allows user" do
            expect_it.to permit(user_context, record)
          end
        end
      end

      permissions :destroy? do
        it "denies user" do
          expect_it.not_to permit(user_context, record)
        end

        context 'permission present → '  do
          before do
            add_permissions('imports.destroy', to_user: user)
          end

          it "denies user" do
            expect_it.not_to permit(user_context, record)
          end
        end
      end

      permissions :edit? do
        it "denies user" do
          expect_it.not_to permit(user_context, record)
        end

        context 'permission present → '  do
          before do
            add_permissions('imports.update', to_user: user)
          end

          it "allows user" do
            expect_it.to permit(user_context, record)
          end
        end
      end

      permissions :new? do
        it "denies user" do
          expect_it.not_to permit(user_context, record)
        end

        context 'permission present → '  do
          before do
            add_permissions('imports.create', to_user: user)
          end

          it "allows user" do
            expect_it.to permit(user_context, record)
          end
        end
      end

      permissions :update? do
        it "denies user" do
          expect_it.not_to permit(user_context, record)
        end

        context 'permission present → '  do
          before do
            add_permissions('imports.update', to_user: user)
          end

          it "allows user" do
            expect_it.to permit(user_context, record)
          end
        end
      end
    end
  end
end
