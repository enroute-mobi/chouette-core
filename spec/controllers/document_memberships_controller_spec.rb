# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
RSpec.describe DocumentMembershipsController, type: :controller do
  def self.with_permission(*permissions, &block)
    context "with permission #{permissions.join(', ')}" do
      before do
        @user.permissions.concat(permissions)
        @user.save!
      end

      instance_eval(&block)
    end
  end

  def self.without_permission(*permissions, &block)
    context "without permission #{permissions.join(', ')}" do
      before do
        @user.permissions.delete(permissions)
        @user.save!
      end

      instance_eval(&block)
    end
  end

  setup_user

  let(:document_provider) { workbench.document_providers.create!(name: 'document_provider_name', short_name: 'titi') }
  let(:document_type) { workbench.workgroup.document_types.create!(name: 'document_type_name', short_name: 'toto') }
  let(:document) do
    Document.create!(
      name: 'Document',
      document_type: document_type,
      document_provider: document_provider,
      file: fixture_file_upload('sample_pdf.pdf'),
      validity_period: (Time.zone.today...Time.zone.today + 1.day)
    )
  end
  let(:unassociated_document) do
    Document.create!(
      name: 'Unassociated',
      document_type: document_type,
      document_provider: document_provider,
      file: fixture_file_upload('sample_pdf.pdf'),
      validity_period: (Time.zone.today...Time.zone.today + 1.day)
    )
  end

  context 'on lines' do
    let(:context) do
      Chouette.create do
        workbench organisation: Organisation.find_by(code: 'first') do
          line :line1, name: 'Line one', published_name: 'First Line', number: 'L1'

          referential lines: [:line1]
        end
      end
    end

    let(:workbench) { context.workbench }
    let(:referential) { context.referential }
    let(:line) { context.line(:line1) }
    let(:redirect_path) { workbench_line_referential_line_document_memberships_path(workbench, line) }

    describe 'GET #index' do
      before do
        line.documents << document
        unassociated_document
      end

      without_permission 'lines.update' do
        it 'does not return unassociated documents' do
          document
          sign_in(@user)
          get :index, params: { workbench_id: workbench.id, line_id: line.id }
          expect(assigns(:document_memberships).map(&:document)).to eq([document])
          expect(assigns(:unassociated_documents).map(&:document)).to eq([])
        end
      end

      with_permission 'lines.update' do
        it 'returns unassociated documents' do
          document
          sign_in(@user)
          get :index, params: { workbench_id: workbench.id, line_id: line.id }
          expect(assigns(:document_memberships).map(&:document)).to eq([document])
          expect(assigns(:unassociated_documents).map(&:document)).to eq([unassociated_document])
        end
      end
    end

    describe 'POST #create' do
      without_permission 'document_memberships.create' do
        with_permission 'lines.update' do
          it 'is forbidden' do
            sign_in(@user)
            post :create, params: { workbench_id: workbench.id, line_id: line.id, document_id: document.id }
            expect(response).to have_http_status(:forbidden)
          end
        end
      end

      with_permission 'document_memberships.create' do
        without_permission 'lines.update' do
          it 'is forbidden' do
            sign_in(@user)
            post :create, params: { workbench_id: workbench.id, line_id: line.id, document_id: document.id }
            expect(response).to have_http_status(:forbidden)
          end
        end

        with_permission 'lines.update' do
          it 'associates document' do
            sign_in(@user)
            post :create, params: { workbench_id: workbench.id, line_id: line.id, document_id: document.id }
            expect(line.reload.documents).to eq([document])
            expect(flash[:success]).to be_present
            expect(response).to redirect_to(redirect_path)
          end

          context 'with document is already associated' do
            before { line.documents << document }

            it 'does not associate document' do
              sign_in(@user)
              post :create, params: { workbench_id: workbench.id, line_id: line.id, document_id: document.id }
              expect(line.reload.documents).to eq([document])
              expect(flash[:error]).to be_present
              expect(response).to redirect_to(redirect_path)
            end
          end
        end
      end
    end

    describe 'DELETE #destroy' do
      before { line.documents << document }

      let(:document_membership) { line.document_memberships.first }

      without_permission 'document_memberships.destroy' do
        with_permission 'lines.update' do
          it 'is forbidden' do
            sign_in(@user)
            delete :destroy, params: { workbench_id: workbench.id, line_id: line.id, id: document_membership.id }
            expect(response).to have_http_status(:forbidden)
          end
        end
      end

      with_permission 'document_memberships.destroy' do
        without_permission 'lines.update' do
          it 'is forbidden' do
            sign_in(@user)
            delete :destroy, params: { workbench_id: workbench.id, line_id: line.id, id: document_membership.id }
            expect(response).to have_http_status(:forbidden)
          end
        end

        with_permission 'lines.update' do
          it 'associates document' do
            sign_in(@user)
            delete :destroy, params: { workbench_id: workbench.id, line_id: line.id, id: document_membership.id }
            expect(line.reload.documents).to eq([])
            expect(flash[:success]).to be_present
            expect(response).to redirect_to(redirect_path)
          end

          context 'when document is not associatied' do
            let(:other_line) { create(:line) }
            let(:document_membership) do
              other_line.documents << unassociated_document
              other_line.document_memberships.last
            end

            it 'is not found' do
              sign_in(@user)
              expect do
                delete :destroy, params: { workbench_id: workbench.id, line_id: line.id, id: document_membership.id }
              end.to raise_error(ActiveRecord::RecordNotFound)
            end
          end
        end
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
