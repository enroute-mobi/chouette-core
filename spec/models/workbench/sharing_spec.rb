# frozen_string_literal: true

RSpec.describe Workbench::Sharing, type: :model do
  subject(:workbench_sharing) { described_class.new }

  let(:context) do
    Chouette.create do
      organisation :organisation do
        user :user
      end
      workbench :workbench
    end
  end
  let(:organisation) { context.organisation(:organisation) }
  let(:user) { context.user(:user) }
  let(:workbench) { context.workbench(:workbench) }

  it { is_expected.to belong_to(:workbench).required }
  it { is_expected.to belong_to(:recipient) }

  it { is_expected.to validate_presence_of(:name) }

  describe 'validation of #workbench' do
    before { workbench_sharing.recipient_type = 'User' }

    it { is_expected.to allow_value(workbench.id).for(:workbench_id) }

    context 'when another workbench sharing already exists without recipient' do
      before { workbench.sharings.create!(name: 'Sharing 1', recipient_type: 'User') }

      it { is_expected.to allow_value(workbench.id).for(:workbench_id) }
    end

    context 'when workbench sharing has a recipient' do
      before { workbench_sharing.recipient = user }

      it { is_expected.to allow_value(workbench.id).for(:workbench_id) }

      context 'when another workbench sharing already exists with the same recipient' do
        before { workbench.sharings.create!(name: 'Sharing 1', recipient: user) }

        it { is_expected.not_to allow_value(workbench.id).for(:workbench_id) }
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
end
