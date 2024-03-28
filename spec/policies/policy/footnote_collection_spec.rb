# frozen_string_literal: true

RSpec.describe Policy::FootnoteCollection, type: :policy do
  let(:resource) { Chouette::Footnote.none }

  describe '.permission_exceptions' do
    subject { described_class.permission_exceptions }

    it do
      is_expected.to eq(
        {
          update_all: 'footnotes.update'
        }
      )
    end
  end

  describe '#update?' do
    subject { policy.update? }
    it { is_expected.to be_falsy }
  end

  describe '#destroy?' do
    subject { policy.destroy? }
    it { is_expected.to be_falsy }
  end

  describe '#update_all?' do
    subject { policy.update_all? }

    it { applies_strategy(Policy::Strategy::Referential) }
    it { applies_strategy(Policy::Strategy::Permission, :update_all) }

    it { is_expected.to be_truthy }
  end
end
