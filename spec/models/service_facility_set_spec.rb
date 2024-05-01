# frozen_string_literal: true

RSpec.describe ServiceFacilitySet do
  subject {service_facility_set.send attribute}

  let(:context) do
    Chouette.create do
      service_facility_set
    end
  end

  subject(:service_facility_set) { context.service_facility_set }

  describe '#uuid' do
    let(:attribute) { :uuid }

    it { is_expected.to be_present }
  end

  describe '#name' do
    let(:attribute) { :name }

    it { is_expected.to be_present }
  end

  describe '#associated_services' do
    let(:attribute) { :associated_services }

    it { is_expected.to be_present }
  end

  describe '#shape_referential' do
    let(:attribute) { :shape_referential }

    it { is_expected.to be_present }
  end
end
