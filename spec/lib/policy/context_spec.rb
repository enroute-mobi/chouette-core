# frozen_string_literal: true

RSpec.describe Policy::Context do
  let(:context) do
    Chouette.create do
      organisation :organisation
      workgroup(owner: :organisation) do
        workbench do
          referential
        end
      end
    end
  end
  let(:organisation) { context.organisation(:organisation) }
  let(:workgroup) { context.workgroup }
  let(:workbench) { context.workbench }
  let(:referential) { context.referential }

  let(:user_permissions) { [] }
  let(:user_organisation) { organisation }
  let(:user) { create(:user, organisation: user_organisation, permissions: user_permissions) }

  subject(:policy_context) { described_class.from(provider) }

  describe Policy::Context::User do
    let(:provider) do
      double(
        current_user: user
      )
    end

    it { is_expected.to have_attributes(user: user) }

    describe '#user_organisation?' do
      subject { policy_context.user_organisation?(organisation) }

      context 'when the organisation is the same as the user' do
        it { is_expected.to be_truthy }
      end

      context 'when the organisation is not the same as the user' do
        let(:user_organisation) { build_stubbed(:organisation) }
        it { is_expected.to be_falsy }
      end
    end

    describe '#permission?' do
      subject { policy_context.permission?('models.permissions') }

      context 'when the user has the permission' do
        let(:user_permissions) { ['models.permissions'] }
        it { is_expected.to be_truthy }
      end

      context 'when the user has not the permission' do
        let(:user_permissions) { ['models.no_permissions'] }
        it { is_expected.to be_falsy }
      end

      context 'when the user permissions is nil' do
        let(:user_permissions) { nil }
        it { is_expected.to be_falsy }
      end
    end
  end

  describe Policy::Context::Workgroup do
    let(:provider_workgroup) { workgroup }
    let(:provider) do
      double(
        current_user: user,
        current_workgroup: provider_workgroup
      )
    end

    it { is_expected.to have_attribute(:user) }
    it { is_expected.to have_attributes(workgroup: provider_workgroup) }

    describe '#workgroup?' do
      subject { policy_context.workgroup?(workgroup) }

      context 'when the workgroup is the same as the context' do
        it { is_expected.to be_truthy }
      end

      context 'when the workgroup is not the same as the context' do
        let(:provider_workgroup) { build_stubbed(:workgroup) }
        it { is_expected.to be_falsy }
      end
    end
  end

  describe Policy::Context::Workbench do
    let(:provider_workbench) { workbench }
    let(:provider) do
      double(
        current_user: user,
        current_workgroup: workgroup,
        current_workbench: provider_workbench
      )
    end

    it { is_expected.to have_attribute(:user) }
    it { is_expected.to have_attribute(:workgroup) }
    it { is_expected.to have_attributes(workbench: provider_workbench) }

    describe '#workbench?' do
      subject { policy_context.workbench?(workbench) }

      context 'when the workbench is the same as the context' do
        it { is_expected.to be_truthy }
      end

      context 'when the workbench is not the same as the context' do
        let(:provider_workbench) { build_stubbed(:workbench) }
        it { is_expected.to be_falsy }
      end
    end

    describe '#permission?' do
      subject { policy_context.permission?('models.permissions') }

      context 'when the user has the permission' do
        before { user.permissions = ['models.permissions'] }

        context 'when the workbench has the restriction' do
          before { workbench.restrictions = ['models.permissions'] }
          it { is_expected.to be_falsy }
        end

        context 'when the workbench has not the restriction' do
          before { workbench.restrictions = ['models.no_permissions'] }
          it { is_expected.to be_truthy }
        end
      end

      context 'when the user has not the permission' do
        before { user.permissions = ['models.no_permissions'] }

        context 'when the workbench has the restriction' do
          before { workbench.restrictions = ['models.permissions'] }
          it { is_expected.to be_falsy }
        end

        context 'when the workbench has not the restriction' do
          before { workbench.restrictions = ['models.no_permissions'] }
          it { is_expected.to be_falsy }
        end
      end
    end
  end

  describe Policy::Context::Referential do
    let(:provider_referential) { referential }
    let(:provider) do
      double(
        current_user: user,
        current_workgroup: workgroup,
        current_workbench: workbench,
        current_referential: provider_referential
      )
    end

    it { is_expected.to have_attribute(:user) }
    it { is_expected.to have_attribute(:workgroup) }
    it { is_expected.to have_attribute(:workbench) }
    it { is_expected.to have_attributes(referential: provider_referential) }

    describe '#referential_read_only?' do
      subject { policy_context.referential_read_only? }

      context 'when the referential is read only' do
        before { referential.archived_at = 1.day.ago }
        it { is_expected.to be_truthy }
      end

      context 'when the referential is not read only' do
        it { is_expected.to be_falsy }
      end
    end
  end
end
