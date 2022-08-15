# frozen_string_literal: true

RSpec.describe Api::V1::PublicationApi::DocumentsController, type: :controller do
  describe 'GET show' do
    subject do
      get :show, params: params
    end

    let(:context) do
      Chouette.create do
        workgroup do
          document_type :test
          publication_api

          document :sample, document_type: :test
          line :sample_line, documents: [:sample], registration_number: 'sample'

          # Referential to be used used as Workgroup.output.current
          referential lines: [:sample_line]
        end
      end
    end

    let(:referential) { context.referential }
    before do
      referential.referential_suite = context.workgroup.output
      context.workgroup.output.update! current: referential
    end

    let(:publication_api) { context.publication_api }
    let(:document_type) { context.document_type(:test) }
    let(:document) { context.document(:sample) }
    let(:line) { context.line(:sample_line) }
    let(:params) do
      {
        slug: publication_api.slug,
        document_type: document_type.short_name,
        line_registration_number: line.registration_number
      }
    end

    context 'when the document is found' do
      before { subject }
      it { expect(response).to have_http_status(:ok) }
    end

    context 'when no line is associated to the registration number' do
      before { params[:line_registration_number] = 'dummy' }

      it { expect { subject }.to raise_error(ActiveRecord::RecordNotFound) }
    end

    context 'when several lines are associated to the registration number' do
      before do 
        other_line = line.line_provider.lines.create! name: "Other"
        # Use the same registration number for other line (validation is skipped for #update_attribute)
        other_line.update_attribute :registration_number, line.registration_number

        # Associate this other line to the referential
        referential.metadatas.create! line_ids: [other_line.id], periodes: [Period.from(:now).during(1.month)]
      end

      it { expect { subject }.to raise_error(ActiveRecord::SoleRecordExceeded) }
    end

    context 'no document is associated to the line' do
      before { line.document_memberships.delete_all }
      it { expect { subject }.to raise_error(ActiveRecord::RecordNotFound) }
    end

    context 'no document with the expected type is associated to the line' do
      before { params[:document_type] = 'dummy' }
      it { expect { subject }.to raise_error(ActiveRecord::RecordNotFound) }
    end

    context 'no document is currently valid' do
      before { document.update validity_period: Period.after(1.month.from_now) }
      it { expect { subject }.to raise_error(ActiveRecord::RecordNotFound) }
    end

    context 'when the associated document has no validity period' do
      before { document.update validity_period: nil }
      before { subject }

      it { expect(response).to have_http_status(:ok) }
    end

    context 'when the associated document has a validity period with include the current Date' do
      before { document.update validity_period: Period.from(1.month.ago).until(1.month.from_now) }
      before { subject }

      it { expect(response).to have_http_status(:ok) }
    end

    context 'when the associated document has a validity period with include the given Date' do
      before do 
        document.update validity_period: Period.after(1.month.from_now)
        params[:valid_on] = 2.months.from_now.to_date.to_s
      end

      before { subject }

      it { expect(response).to have_http_status(:ok) }
    end
  end
end
