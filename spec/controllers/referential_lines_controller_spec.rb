# frozen_string_literal: true

describe ReferentialLinesController, :type => :controller do
  login_user

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

  describe "GET show" do
    let(:request){ get :show, params: { workbench_id: workbench.id, referential_id: referential.id, id: line.id }}

    it 'returns http success' do
      expect(request).to have_http_status :ok
    end
  end
end
