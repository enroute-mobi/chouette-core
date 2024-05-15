# frozen_string_literal: true

RSpec.describe FootnotesController, :type => :controller do
  login_user permissions: []

  let(:context) do
    Chouette.create do
      workbench organisation: Organisation.find_by(code: 'first') do
        line :line
        referential lines: %i[line]
      end
    end
  end
  let(:workbench) { context.workbench }
  let(:referential) { context.referential }
  let(:line) { context.line(:line) }

  describe "GET edit_all" do
    let(:request) do
      get :edit_all, params: { line_id: line.id, referential_id: referential.id, workbench_id: workbench.id }
    end

    it 'should respond with 403' do
      expect(request).to have_http_status 403
    end

    with_permission "footnotes.update" do
      it 'returns http success' do
        expect(request).to have_http_status :ok
      end

      context "with an archived referential" do
        before(:each) do
          referential.archive!
        end
        it 'should respond with 403' do
          expect(request).to have_http_status 403
        end
      end
    end
  end

  describe "PATCH update_all" do
    let(:request) do
      patch :update_all, params: {
        line_id: line.id,
        referential_id: referential.id,
        workbench_id: workbench.id,
        line: { footnotes_attributes: [{ code: '' }] }
      }
    end

    it 'should respond with 403' do
      expect(request).to have_http_status 403
    end

    with_permission "footnotes.update" do
      it 'redirects' do
        expect(request).to have_http_status :redirect
      end
    end

    context 'when destroying a footnote' do
      before do
        line.footnotes.create code: 'foo'
      end
      let(:request) do
        patch :update_all, params: {
          line_id: line.id,
          referential_id: referential.id,
          workbench_id: workbench.id,
          line: { footnotes_attributes: [{ id: line.footnotes.last.id, _destroy: '1', code: 'foo', label: 'bar' }] }
        }
      end

      it 'should destroy marked footnotes' do
        expect{ request }.to change { line.footnotes.count }.to 0
      end
    end
  end
end
