RSpec.describe Api::V1::LineReferentialsController do

  describe "POST webhook" do

    context "without authentication" do
      it "returns a 401 status" do
        get :webhook, params: { id: 1 }
        expect(response.status).to eq(401)
      end
    end

    class MockSynchronisation

      attr_accessor :source

      def update_or_create
        @update_or_create = true
      end

      def update_or_create?
        @update_or_create
      end

      def delete(deleted_ids)
        @deleted_ids = deleted_ids
      end

      def counts
        @counts ||= {}
      end

    end

    context "with authentication" do

      let(:token) { 'secret' }
      let(:event_attributes) { { type: "destroyed", stop_place: { "id" => "42" } } }

      before do
        allow(ApiKey).to receive(:find_by).with(token: token).and_return(double(workgroup: double))
        allow(controller).to receive(:line_referential).and_return(double)
        allow(controller).to receive(:synchronization).and_return(MockSynchronisation.new)
        request.env['HTTP_AUTHORIZATION'] =
          ActionController::HttpAuthentication::Token.encode_credentials(token)
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

    %w{lines line operators operator networks network}.each do |resource_name|
      it "includes '#{resource_name}' attribute as string" do
        expect(permitted_attributes).to include(resource_name)
      end
    end

    %w{line operator network}.each do |resource_name|
      it "includes '#{resource_name}' attribute as hash" do
        expect(permitted_attributes.last).to include(resource_name => {})
      end
    end

    %w{lines operators networks}.each do |resource_name|
      it "includes '#{resource_name}' attribute as array" do
        expect(permitted_attributes.last).to include(resource_name => [:id])
      end
    end

  end

end
