RSpec.describe ComplianceCheckSetPolicy, type: :policy do
  
  subject { described_class.new UserContext.new(user), compliance_check_set }

  describe "for show action" do
    context 'when user is ComplianceCheckSet owner' do
      let(:context) do
        Chouette.create do
          organisation(:organisation) { user :user }
          workbench organisation: :organisation do
            compliance_check_set user: :user
          end
        end
      end
      let(:compliance_check_set) { context.compliance_check_set }
      let(:user) { context.user(:user) }
      it { is_expected.to permit_action(:show) }
    end

    context 'when user is Workgroup owner' do
      let(:context) do
        Chouette.create do
          organisation(:owner_organisation) { user :owner_user }
          organisation { user :another_user }
          workgroup owner: :owner_organisation do
            compliance_check_set user: :another_user
          end
        end
      end
      let(:compliance_check_set) { context.compliance_check_set }
      let(:user) { context.user(:owner_user) }
      it { is_expected.to permit_action(:show) }
    end

    context 'when user belongs to another organisation in the same Workgroup' do
      let(:context) do
        Chouette.create do
          organisation(:organisation) { user :user }
          organisation(:other_organisation) { user :other_user }
          workgroup do
            workbench organisation: :organisation
            workbench organisation: :other_organisation do
              compliance_check_set user: :other_user
            end
          end
        end
      end
      let(:compliance_check_set) { context.compliance_check_set }
      let(:user) { context.user(:user) }
      it { is_expected.to forbid_action(:show) }
    end

    context 'when user belongs to same organisation and the same Workgroup' do
      let(:context) do
        Chouette.create do
          organisation(:organisation) do
            user :user
            user :other_user
          end
          workbench organisation: :organisation do
            compliance_check_set user: :other_user
          end
        end
      end
      let(:compliance_check_set) { context.compliance_check_set }
      let(:user) { context.user(:user) }
      it { is_expected.to permit_action(:show) }
    end
  end

end
