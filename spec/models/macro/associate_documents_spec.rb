# frozen_string_literal: true

RSpec.describe Macro::AssociateDocuments do
  it 'should be one of the available Macro' do
    expect(Macro.available).to include(described_class)
  end

  describe Macro::AssociateDocuments::Run do
    let(:macro_run) do
      described_class.create(
        macro_list_run: macro_list_run,
        position: 0,
        target_model: target_model,
        document_code_space: document_code_space,
        model_code_space: model_code_space
      )
    end

    let(:macro_list_run) do
      Macro::List::Run.create referential: referential, workbench: workbench
    end

    describe '#run' do
      subject { macro_run.run }

      let(:context) do
        Chouette.create do
          code_space :document_code_space, short_name: 'document_code_space'
          code_space :stop_area_code_space, short_name: 'stop_area_code_space'
          code_space :line_code_space, short_name: 'line_code_space'

          workbench organisation: Organisation.find_by_code('first') do
            stop_area :first, name: 'Stop Area Name', codes: { stop_area_code_space: 'dummy' }
            stop_area :middle
            stop_area :last

            line :line, name: 'Line Name'
            line :other

            referential lines: [:line, :other] do
              route stop_areas: %i[first middle last]
            end
          end
        end
      end

      let(:referential) { context.referential }
      let(:workbench) { context.workbench }
      let(:line) { context.line(:line) }
      let(:stop_area) { context.stop_area(:first) }

      let(:document_provider) do 
        workbench.document_providers.create(name: 'document_provider_name', short_name: 'short_name')
      end
      let(:document_type) { workbench.workgroup.document_types.create(name: 'document_type_name', short_name: 'short_name') }
      let(:file) { fixture_file_upload('sample_pdf.pdf') }

      let(:document) do
        document_provider.documents.create!(
          name: 'test',
          document_type_id: document_type.id,
          file: file,
          validity_period: (Time.zone.today...Time.zone.today + 1.day))
      end

      let(:expected_message) do
        an_object_having_attributes(
          message_attributes: {
            'document_name' => 'test',
            'model_name' => model_name
          }
        )
      end

      let(:document_code_space) { context.code_space(:document_code_space).id }
      let(:line_code_space) { context.code_space(:line_code_space).id }
      let(:stop_area_code_space) { context.code_space(:stop_area_code_space).id }

      before do
         referential.switch
         document.codes.create(code_space_id: document_code_space, value: 'dummy')
         line.codes.create(code_space_id: line_code_space, value: 'dummy' )
      end

      describe 'StopArea' do
        let(:target_model) { 'StopArea' }
        let(:model_code_space) { stop_area_code_space }
        let(:model_name) { 'Stop Area Name' }

        it 'Should associate document with stop area' do
          expect { subject }.to change { document.memberships.count }.from(0).to(1)
          expect(macro_run.macro_messages).to include(expected_message)
        end
      end

      describe 'Line' do
        let(:target_model) { 'Line' }
        let(:model_code_space) { line_code_space }
        let(:model_name) { 'Line Name' }

        it 'Should associate document with line' do
          expect { subject }.to change { document.memberships.count }.from(0).to(1)
          expect(macro_run.macro_messages).to include(expected_message)
        end
      end
    end
  end
end
