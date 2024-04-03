# coding: utf-8
RSpec.describe ImportPolicy, type: :pundit_policy do

  let(:record) { create :import }
  before { user.organisation = create(:organisation) }

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

  context "when the workbench belongs to another organisation (same workgroup) but i am the owner of the workgroup" do
    before do
      record.workbench.workgroup.update owner_id: user.organisation_id
      allow(user.workgroups).to receive(:pluck).with(:id).and_return [record.workbench.workgroup_id]
    end

    permissions :index? do
      it "allows user" do
        expect_it.to permit(user_context, record)
      end
    end
    permissions :show? do
      it "allow user" do
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

  describe "#option?" do

    subject(:policy) { ImportPolicy.new user_context, record }

    it "allows an option be default" do
      expect(policy).to permit_action(:option, :dummy)
    end

    it "uses the associated method if exists" do
      expect(policy).to receive(:option_flag_urgent?).and_return(false)
      expect(policy).to forbid_action(:option, :flag_urgent)
    end

  end

  describe "#option_flag_urgent?" do
    
    context "user_context contains no workbench" do
      subject(:policy) { ImportPolicy.new user_context, record }

      context "with permission 'referentials.flag_urgent'" do
        before { add_permissions 'referentials.flag_urgent', to_user: user }
        it "allows user" do
          expect_it.to permit_action(:option, :flag_urgent)
        end
      end

      context "without permission 'referentials.flag_urgent'" do
        before { remove_permissions 'referentials.flag_urgent', from_user: user }
        it "allows user" do
          expect_it.to forbid_action(:option, :flag_urgent)
        end
      end
    end

    context "user_context contains a permissive workbench" do
      let(:permissive_workbench) { create :workbench, restrictions: [] }
      let( :user_context_with_permissive_workbench ) { create_user_context(user, referential, permissive_workbench)  }
      subject(:policy) { ImportPolicy.new user_context_with_permissive_workbench, record }

      context "with permission 'referentials.flag_urgent'" do
        before { add_permissions 'referentials.flag_urgent', to_user: user }
        it "allows user" do
          expect_it.to permit_action(:option, :flag_urgent)
        end
      end

      context "without permission 'referentials.flag_urgent'" do
        before { remove_permissions 'referentials.flag_urgent', from_user: user }
        it "allows user" do
          expect_it.to forbid_action(:option, :flag_urgent)
        end
      end
    end

    context "user_context contains a restrictive workbench" do
      let(:restrictive_workbench) { create :workbench, restrictions: ['referentials.flag_urgent'] }
      let( :user_context_with_restrictive_workbench ) { create_user_context(user, referential, restrictive_workbench)  }
      subject(:policy) { ImportPolicy.new user_context_with_restrictive_workbench, record }

      context "with permission 'referentials.flag_urgent'" do
        before { add_permissions 'referentials.flag_urgent', to_user: user }
        it "allows user" do
          expect_it.to forbid_action(:option, :flag_urgent)
        end
      end

      context "without permission 'referentials.flag_urgent'" do
        before { remove_permissions 'referentials.flag_urgent', from_user: user }
        it "allows user" do
          expect_it.to forbid_action(:option, :flag_urgent)
        end
      end
    end

  end

end
