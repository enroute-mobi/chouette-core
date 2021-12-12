RSpec.describe Api::V1::LineReferentialsController do

  describe "POST webhook" do

    context "without authentication" do
      it "returns a 401 status" do
        get :webhook, params: { id: 1 }
        expect(response.status).to eq(401)
      end
    end

    class self::MockSynchronisation

      attr_accessor :source

      def update_or_create
        @update_or_create = true
      end

      def update_or_create?
        @update_or_create
      end

      def delete(resource_name, deleted_ids)
        @resource_name = resource_name
        @deleted_ids = deleted_ids
      end

    end

    def mock_synchronisation
      @mock_synchonisation ||= self.class::MockSynchronisation.new
    end

    context "with authentication" do

      let(:token) { 'secret' }
      let(:event_attributes) { { type: "destroyed", stop_place: { "id" => "42" } } }
      let(:context) do
        Chouette.create do
          # line_referential is created along the workbench in Chouette::Factory hierarchy
          workbench
        end
      end
      let(:api_key) { create :api_key, workbench: context.workbench, token: token }

      before do
        allow(controller).to receive(:line_referential).and_return(double)
        allow(controller).to receive(:synchronization).and_return(mock_synchronisation)
        request.env['HTTP_AUTHORIZATION'] =
          ActionController::HttpAuthentication::Token.encode_credentials(token)
        api_key
      end

      describe "destroyed event" do

        let(:event_attributes) do
          {
            type: "destroyed",
            lines: [{ "id" => "42" },{ "id" => "43" }],
          }
        end

        it "assigns event with provided attributes" do
          get :webhook, params: { id: 1, line_referential: event_attributes }
          expect(assigns(:event)).to have_attributes(event_attributes)
        end

      end

      it "returns a 200 status" do
        get :webhook, params: { id: 1, line_referential: event_attributes }
        expect(response.status).to eq(200)
      end

    end

  end

  describe "#permitted_attributes" do

    subject(:permitted_attributes) { controller.send :permitted_attributes }

    it "includes 'type' attribute" do
      expect(permitted_attributes).to include("type")
    end

    %w{lines line operators operator networks network notice notices}.each do |resource_name|
      it "includes '#{resource_name}' attribute as string" do
        expect(permitted_attributes).to include(resource_name)
      end
    end

    %w{line operator network notice}.each do |resource_name|
      it "includes '#{resource_name}' attribute as hash" do
        expect(permitted_attributes.last).to include(resource_name => {})
      end
    end

    %w{lines operators networks notices}.each do |resource_name|
      it "includes '#{resource_name}' attribute as array" do
        expect(permitted_attributes.last).to include(resource_name => [:id])
      end
    end

  end

end
