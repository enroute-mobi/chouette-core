# frozen_string_literal: true

RSpec.describe ImportDecorator, type: %i[helper decorator] do
  include Support::DecoratorHelpers

  let(:context) do
    Chouette.create do
      # To match organisation used by login_user
      organisation = Organisation.find_by(code: 'first')
      workgroup owner: organisation do
        workbench organisation: organisation do
          referential
        end
      end
    end
  end
  let(:user) { build_stubbed(:user) }

  let(:referential) { context.referential }
  let(:workbench) { referential.workbench }

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
