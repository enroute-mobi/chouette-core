# frozen_string_literal: true

RSpec.describe Authentication::Base, type: :model do
  it { is_expected.to belong_to(:organisation).required }
  it { is_expected.to validate_presence_of(:name) }

  describe '.nullable_attributes' do
    subject { described_class.nullable_attributes }
    it do
      is_expected.to match_array(
        %i[
          subtype
        ]
      )
    end
  end
end
