# frozen_string_literal: true

RSpec.describe Export::Gtfs::Contracts do
  let(:export_scope) { Export::Scope::All.new referential }

  let(:export) do
    Export::Gtfs.new(
      export_scope: export_scope,
      workbench: workbench,
      workgroup: workgroup,
      referential: referential
    )
  end

  let(:referential) { context.referential }
  let(:workbench) { context.workbench }
  let(:workgroup) { context.workgroup }

  subject(:part) do
    Export::Gtfs::Contracts.new export
  end

  describe '#perform' do
    let(:context) do
      Chouette.create do
        company :first, name: 'first dummy'
        company :second, name: 'second dummy'

        vehicle_journey :first, objectid: 'objectid1', company: :first
        vehicle_journey :second, objectid: 'objectid2', company: :second
      end
    end

    let(:first_company) { context.company(:first) }
    let(:first_vehicle_journey) { context.vehicle_journey(:first) }
    let(:line) { first_vehicle_journey.line }

    before do
      referential.switch
      workbench.contracts.create!(name: first_company.name, company: first_company, line_ids: [line.id])

      allow(part.code_provider).to receive(:code).with(line) { 'route_id' }
    end

    describe 'exported attributions' do
      subject { export.target.attributions }

      before { part.perform }

      let(:expected_attributes) do
        {
          organization_name: 'first dummy',
          route_id: 'route_id',
          is_producer: 1
        }
      end

      it 'should export attribution of the first company' do
        is_expected.to contain_exactly(an_object_having_attributes(expected_attributes))
      end
    end
  end
end

RSpec.describe Export::Gtfs::Contracts::Decorator do
  subject(:decorator) { described_class.new contract }

  let(:contract) { Contract.new }

  describe '#attributions' do
    subject { decorator.attributions }

    context 'when Contract is associated to a Line outside the export scope' do
      let(:included_line) { Chouette::Line.new registration_number: 'included' }
      let(:excluded_line) { Chouette::Line.new registration_number: 'excluded' }

      before do
        allow(contract).to receive(:lines).and_return([included_line, excluded_line])
      end

      before do
        route_id_for = ->(line) { line.registration_number unless line == excluded_line }
        allow(decorator).to receive(:route_id).and_invoke(route_id_for)
      end

      it { is_expected.to match_array(an_object_having_attributes(route_id: 'included')) }
    end
  end
end
