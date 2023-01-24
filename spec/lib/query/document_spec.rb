RSpec.describe Query::Document do
  describe '#query' do
    let(:query) { Query::Document.new(Document.all) }

    let(:context) do
      Chouette.create do
        workbench organisation: Organisation.find_by_code('first') do
          line :first
        end
      end
    end

    let(:workbench) { context.workbench }

    let(:document_provider) { workbench.document_providers.create(name: 'document_provider_name') }
    let(:document_type_1) do
      workbench.workgroup.document_types.create(name: 'document_type_name 1', short_name: 'type1')
    end
    let(:document_type_2) do
      workbench.workgroup.document_types.create(name: 'document_type_name 2', short_name: 'type2')
    end
    let(:file) { fixture_file_upload('sample_pdf.pdf') }

    let(:today) { Time.zone.today }
    
    let(:selected) do
      Document.create({
        name: 'Selected doc',
        document_type_id: document_type_1.id,
        document_provider_id: document_provider.id,
        file: file,
        validity_period: (today..today + 1.day)
      })
    end

    let(:second) do
      Document.create({
        name: 'Doc 1',
        document_type_id: document_type_2.id,
        document_provider_id: document_provider.id,
        file: file,
        validity_period: (today + 2.day..today + 4.day)
      })
    end

    let(:third) do
      Document.create({
        name: 'Doc 2',
        document_type_id: document_type_2.id,
        document_provider_id: document_provider.id,
        file: file,
        validity_period: (today + 2.day..today + 4.day)
      })
    end

    let(:scope) { query.send(criteria_id, criteria_value).scope }

    subject { scope == [selected] }

    describe '#document_type' do
      let(:criteria_id) { 'document_type' }
      let(:criteria_value) { document_type_1 }

      it { is_expected.to be_truthy }
    end

    describe '#in_period' do
      let(:criteria_id) { 'in_period' }
      let(:criteria_value) { Period.new(from: today, to: (today + 1.day)) }

      it { is_expected.to be_truthy }
    end

  end
end