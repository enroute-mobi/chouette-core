# frozen_string_literal: true

RSpec.describe DocumentDecorator, type: %i[helper decorator] do
  include Support::DecoratorHelpers

  let(:context) do
    Chouette.create do
      workbench organisation: Organisation.find_by(code: 'first') do
        line :first
      end
    end
  end
  let(:user) { build_stubbed(:user) }

  let(:workbench) { context.workbench }
  let(:line) { context.line(:first) }

  let(:document_provider) { workbench.document_providers.create!(name: 'document_provider_name', short_name: 'titi') }
  let(:document_type) { workbench.workgroup.document_types.create!(name: 'document_type_name', short_name: 'toto') }
  let(:file) { fixture_file_upload('sample_pdf.pdf') }
  let(:document) do
    Document.create(
      name: 'test',
      document_type_id: document_type.id,
      document_provider_id: document_provider.id,
      file: file,
      validity_period: Time.zone.today...Time.zone.today + 1.day
    )
  end

  let(:object) { document.decorate }

  describe 'action_links' do
    describe 'secondary' do
      describe 'show' do
        describe '#disabled' do
          context 'when file is attached' do
            it 'should not be disabled' do
              expect(subject.action_links(:show).map(&:disabled?)).to eq([false])
            end
          end

          context 'when file is not attached' do
            let(:file) { nil }

            it 'should be disabled' do
              expect(subject.action_links(:show).map(&:disabled?)).to eq([true])
            end
          end
        end
      end
    end
  end
end
