# frozen_string_literal: true

describe Equipement, type: :model do
  let(:context) do
    Chouette.create do
      stop_area :stop_area
      shape_provider do
        equipement :equipement, stop_area: :stop_area
      end
    end
  end

  subject(:equipement) { context.equipement(:equipement) }

  it { should validate_presence_of(:name) }
  it { should belong_to(:stop_area).required }
  it { should belong_to(:shape_provider).required }

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
    expect(equipement).to be_valid
  end
end
