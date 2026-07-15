# frozen_string_literal: true

describe Equipment, type: :model do
  let(:context) do
    Chouette.create do
      equipment
    end
  end

  subject(:equipment) { context.equipment }

  it { should validate_presence_of(:name) }
  it { should belong_to(:stop_area).required }

  %i[
    mobility_impaired_accessibility
    wheelchair_accessibility
    step_free_accessibility
    escalator_free_accessibility
    lift_free_accessibility
    audible_signals_availability
    visual_signs_availability
  ].each do |attribute|
    it { is_expected.to enumerize(attribute).in(:unknown, :yes, :no, :partial).with_default(:unknown) }
  end

  it 'is valid' do
    expect(equipment).to be_valid
  end
end
