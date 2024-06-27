# frozen_string_literal: true

RSpec.describe Workbench::Sharing, type: :model do
  subject(:workbench_sharing) { workbench.sharings.new }

  let(:context) do
    Chouette.create do
      organisation :organisation do
        user :user
      end
      workgroup owner: :organisation do
        workbench :workbench
      end
    end
  end
  let(:organisation) { context.organisation(:organisation) }
  let(:user) { context.user(:user) }
  let(:workbench) { context.workbench(:workbench) }

  it { is_expected.to belong_to(:workbench).required }
  it { is_expected.to belong_to(:recipient) }

  it { is_expected.to validate_presence_of(:name) }

  describe 'validation' do
    describe '#recipient_id' do
      describe 'unicity' do
        before { workbench_sharing.recipient_type = 'User' }

        it { is_expected.to allow_value(nil).for(:recipient_id) }

        context 'when another workbench sharing already exists without recipient' do
          before { workbench.sharings.create!(name: 'Sharing 1', recipient_type: 'User') }

          it { is_expected.to allow_value(nil).for(:recipient_id) }
        end

        context 'when workbench sharing has a recipient' do
          it { is_expected.to allow_value(user.id).for(:recipient_id) }

          context 'when another workbench sharing already exists with the same recipient' do
            before { workbench.sharings.create!(name: 'Sharing 1', recipient: user) }

            it { is_expected.not_to allow_value(user.id).for(:recipient_id) }
          end
        end
      end

      describe 'invalid' do
        context 'with User' do
          before { workbench_sharing.recipient_type = 'User' }

          it { is_expected.to allow_value(nil).for(:recipient_id) }

          it 'is expected to allow workbench organisation user id' do
            is_expected.to allow_value(user.id).for(:recipient_id)
          end

          it 'is expected to not allow random user id' do
            is_expected.not_to allow_value(Chouette.create { user }.user.id).for(:recipient_id)
          end

          context 'on update' do
            before { workbench_sharing.update(name: 'Test') }

            it 'is expected to allow workbench organisation user id' do
              is_expected.to allow_value(user.id).for(:recipient_id)
            end

            it 'is expected to allow random user id' do
              is_expected.to allow_value(Chouette.create { user }.user.id).for(:recipient_id)
            end
          end

          it 'can be created in Chouette::Factory with random user id' do
            context = Chouette.create do
              user :user
              workbench_sharing recipient: :user
            end
            expect(context.workbench_sharing).to be_persisted
            expect(context.workbench_sharing.recipient_id).to eq(context.user(:user).id)
            expect(context.workbench_sharing).to be_valid
          end
        end

        context 'with Organisation' do
          before { workbench_sharing.recipient_type = 'Organisation' }

          it { is_expected.to allow_value(nil).for(:recipient_id) }

          it 'is expected to not allow workbench organisation id' do
            is_expected.not_to allow_value(organisation.id).for(:recipient_id)
          end

          it 'is expected to not allow random organisation id' do
            is_expected.not_to allow_value(Chouette.create { organisation }.organisation.id).for(:recipient_id)
          end

          context 'on update' do
            before { workbench_sharing.update(name: 'Test') }

            it 'is expected to allow workbench organisation id' do
              is_expected.to allow_value(organisation.id).for(:recipient_id)
            end

            it 'is expected to allow random organisation id' do
              is_expected.to allow_value(Chouette.create { organisation }.organisation.id).for(:recipient_id)
            end
          end

          it 'can be created in Chouette::Factory with random organisation id' do
            context = Chouette.create do
              organisation :organisation
              workbench_sharing recipient: :organisation
            end
            expect(context.workbench_sharing).to be_persisted
            expect(context.workbench_sharing.recipient_id).to eq(context.organisation(:organisation).id)
            expect(context.workbench_sharing).to be_valid
          end
        end
      end
    end
  end

  it { is_expected.to allow_value('User').for(:recipient_type) }
  it { is_expected.to allow_value('Organisation').for(:recipient_type) }
  it { is_expected.not_to allow_value('').for(:recipient_type) }
  it { is_expected.not_to allow_value(nil).for(:recipient_type) }

  it { is_expected.to allow_value('S-123-456-789').for(:invitation_code) }
  context 'when another workbench sharing already has "S-123-456-789" invitation code' do
    before { workbench.sharings.create!(name: 'Sharing 1', recipient_type: 'User', invitation_code: 'S-123-456-789') }

    it { is_expected.not_to allow_value('S-123-456-789').for(:invitation_code) }

    context 'but it is not pending' do
      before { workbench_sharing.recipient = user }

      it { is_expected.to allow_value('S-123-456-789').for(:invitation_code) }
    end
  end

  describe '#invitation_code' do
    subject { workbench_sharing.invitation_code }

    context 'when pending' do
      let(:workbench_sharing) { workbench.sharings.create!(name: 'Sharing 1', recipient_type: 'User') }

      it 'sets invitation_code' do
        expect(subject).to match(/\AS-\d{3}-\d{3}-\d{3}\z/)
      end
    end

    context 'when non-pending' do
      let(:workbench_sharing) { workbench.sharings.create!(name: 'Sharing 1', recipient: user) }

      it 'does not set invitation_code' do
        expect(subject).to be_nil
      end
    end
  end

  describe '#pending?' do
    subject { workbench_sharing.pending? }

    context 'without recipient' do
      let(:workbench_sharing) { described_class.new(recipient: nil) }

      it { is_expected.to eq(true) }
    end

    context 'with recipient' do
      let(:workbench_sharing) { described_class.new(recipient: Chouette.create { user }.user) }

      it { is_expected.to eq(false) }
    end
  end

  describe '#status' do
    subject { workbench_sharing.status }

    context 'without recipient' do
      let(:workbench_sharing) { described_class.new(recipient: nil) }

      it { is_expected.to eq(:pending) }
    end

    context 'with recipient' do
      let(:workbench_sharing) { described_class.new(recipient: Chouette.create { user }.user) }

      it { is_expected.to eq(:confirmed) }
    end
  end

  describe '#candidate_user_recipients' do
    subject { workbench_sharing.candidate_user_recipients }

    let(:context) do
      Chouette.create do
        organisation :organisation do
          user :user
        end
        organisation :other_organisation do
          user :other_user
        end
        workgroup owner: :organisation do
          workbench :workbench
        end
      end
    end

    it 'returns only users of workbench organisation' do
      expect(subject).to eq([user])
    end
  end
end
