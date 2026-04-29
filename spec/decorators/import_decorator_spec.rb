# frozen_string_literal: true

RSpec.describe ImportDecorator, type: %i[helper decorator] do
  let(:context_context) do
    Chouette.create do
      workbench
    end
  end
  let(:workbench) { context_context.workbench }
  let(:context) { { parent: workbench } }

  let(:file) { fixture_file_upload('google-sample-feed.zip') }
  let(:import) do
    Import::Workbench.create(
      name: 'Test',
      creator: 'test',
      file: file,
      workbench: workbench
    )
  end

  let(:object) { import.decorate }

  describe 'action_links' do
    describe 'primary' do
      describe 'show' do
        describe '#disabled' do
          context 'when file is attached' do
            it 'should not be disabled' do
              expect(subject.action_links(:show, group: :primary).map(&:disabled?)).to eq([false])
            end
          end

          context 'when file is not attached' do
            let(:file) { nil }

            it 'should be disabled' do
              expect(subject.action_links(:show, group: :primary).map(&:disabled?)).to eq([true])
            end
          end
        end
      end
    end

    describe 'secondary' do
      describe 'show' do
        describe '#disabled' do
          context 'when messages are present' do
            it 'should not be disabled' do
              expect(subject.action_links(:show, group: :secondary).map(&:disabled?)).to eq([false])
            end
          end

          context 'when no messages are present' do
            let(:import) do
              Import::Workbench.create(
                name: 'Test',
                creator: 'test',
                file: file,
                workbench: workbench,
                children: []
              )
            end

            it 'should be disabled' do
              expect(subject.action_links(:show, group: :secondary).map(&:disabled?)).to eq([true])
            end
          end
        end
      end
    end
  end
end
