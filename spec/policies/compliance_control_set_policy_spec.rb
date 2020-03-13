
RSpec.describe ComplianceControlSetPolicy do
  let( :user )  { create :user, organisation: create(:organisation) }
  let( :record ){ build_stubbed :compliance_control_set }
  before { stub_policy_scope(record) }

  permissions :create? do
    it_behaves_like 'permitted policy outside referential', 'compliance_control_sets.create'
  end

  permissions :update? do
    it 'denies user' do
      expect_it.to_not permit(user_context, record)
      add_permissions('compliance_control_sets.update', to_user: user)
      expect_it.to_not permit(user_context, record)
    end

    context "when owned by the user's organisation" do
      before {
        record.organisation = user.organisation
      }
      it_behaves_like 'permitted policy outside referential', 'compliance_control_sets.update'
    end
  end

  permissions :clone? do
    it 'denies user' do
      expect_it.to_not permit(user_context, record)
      add_permissions('compliance_control_sets.create', to_user: user)
      expect_it.to_not permit(user_context, record)
    end

    context "when owned by the user's organisation" do
      before {
        record.organisation = user.organisation
      }
      it_behaves_like 'permitted policy outside referential', 'compliance_control_sets.create'
    end

    context "when owned by the user's workgroup owner" do
      before {
        owner = create(:organisation)
        workgroup = create :workgroup, owner: owner
        create :workbench, organisation: user.organisation, workgroup: workgroup
        record.organisation = owner
      }
      it_behaves_like 'permitted policy outside referential', 'compliance_control_sets.create'
    end
  end

  permissions :destroy? do
    it 'denies user' do
      expect_it.to_not permit(user_context, record)
      add_permissions('compliance_control_sets.destroy', to_user: user)
      expect_it.to_not permit(user_context, record)
    end

    context "when owned by the user's organisation" do
      before {
        record.organisation = user.organisation
      }
      it_behaves_like 'permitted policy outside referential', 'compliance_control_sets.destroy'
    end
  end
end
