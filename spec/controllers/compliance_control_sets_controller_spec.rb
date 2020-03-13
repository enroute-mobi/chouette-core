
RSpec.describe ComplianceControlSetsController, type: :controller do
  login_user

  let(:owner){ create :organisation }
  let(:workgroup){create :workgroup, owner: owner}
  let(:other_organisation){
    o  = create :organisation
    @owner_workbench = create :workbench, workgroup: workgroup, organisation: o
    o
  }

  before do
    @workbench = create :workbench, workgroup: workgroup, organisation: @user.organisation
  end

  let!(:same_organisation_cc_set){ create :compliance_control_set, organisation: @user.organisation }
  let!(:different_organisation_cc_set){ create :compliance_control_set, organisation: other_organisation }
  let!(:workgroups_owner_cc_set){ create :compliance_control_set, organisation: owner }

  describe "GET index" do
    it 'should be successful' do
      get :index
      expect(response).to be_successful
      expect(assigns(:compliance_control_sets)).to include(same_organisation_cc_set)
      expect(assigns(:compliance_control_sets)).to_not include(workgroups_owner_cc_set)
      expect(assigns(:compliance_control_sets)).to_not include(different_organisation_cc_set)
    end

    context "with filters" do
      let(:assigned_to_slots){ [""] }

      it "should filter the output" do
        get :index, params: { q: {assigned_to_slots: assigned_to_slots} }
        expect(response).to be_successful
        expect(assigns(:compliance_control_sets)).to include(same_organisation_cc_set)
        expect(assigns(:compliance_control_sets)).to_not include(workgroups_owner_cc_set)
        expect(assigns(:compliance_control_sets)).to_not include(different_organisation_cc_set)
      end

      context "when filtering on one assigned slots" do
        let(:assigned_to_slots){ ["after_import_by_workgroup", ""] }
        before do
          @workbench.update owner_compliance_control_set_ids: {after_import_by_workgroup: same_organisation_cc_set.id}
        end

        it "should filter the output" do
          get :index, params: { q: { assigned_to_slots: assigned_to_slots }}
          expect(response).to be_successful
          expect(assigns(:compliance_control_sets)).to include(same_organisation_cc_set)
          expect(assigns(:compliance_control_sets)).to_not include(workgroups_owner_cc_set)
          expect(assigns(:compliance_control_sets)).to_not include(different_organisation_cc_set)
        end
      end

      context "when filtering on multiple assigned slots" do
        let(:assigned_to_slots){ ["after_import_by_workgroup", "before_merge", ""] }
        let!(:other_cc_set){
          create :compliance_control_set, organisation: @user.organisation
        }
        before do
          @workbench.update owner_compliance_control_set_ids: {after_import_by_workgroup: same_organisation_cc_set.id, before_merge: other_cc_set.id}
          @owner_workbench.update owner_compliance_control_set_ids: {before_merge: workgroups_owner_cc_set.id}
        end

        it "should filter the output" do
          get :index, params: { q: { assigned_to_slots: assigned_to_slots }}
          expect(response).to be_successful
          expect(assigns(:compliance_control_sets).object).to include(same_organisation_cc_set)
          expect(assigns(:compliance_control_sets).object).to include(other_cc_set)
          expect(assigns(:compliance_control_sets).object).to_not include(workgroups_owner_cc_set)
          expect(assigns(:compliance_control_sets).object).to_not include(different_organisation_cc_set)
        end
      end
    end
  end
end
