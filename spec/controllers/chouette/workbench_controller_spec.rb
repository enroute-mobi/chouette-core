# frozen_string_literal: true

describe Chouette::WorkbenchController, type: :controller do
  describe 'access' do
    # NOTE: controller do; end should be enough but inherited-resources requires a named class
    # so we have to define a temporary named class and manually define routes

    # rubocop:disable Lint/ConstantDefinitionInBlock,Style/ClassAndModuleChildren
    class self::DummysController < described_class
      def index
        head :ok
      end
    end
    # rubocop:enable Lint/ConstantDefinitionInBlock,Style/ClassAndModuleChildren

    describe self::DummysController, type: :controller do
      login_user

      let(:context) do
        Chouette.create do
          organisation = Organisation.find_by(code: 'first')
          workbench :organisation_workbench, organisation: organisation
          workbench :shared_with_user_workbench do
            workbench_sharing recipient: organisation.users.first
          end
          workbench :shared_with_organisation_workbench do
            workbench_sharing recipient: organisation
          end
          workbench :other_workbench
        end
      end

      # copied from rspec-rails lib/rspec/rails/example/controller_example_group.rb
      before do
        @orig_routes = routes
        resource_path = @controller.controller_path
        resource_module = resource_path.rpartition('/').first.presence
        resource_as = "anonymous_#{resource_path.tr('/', '_')}"
        self.routes = ActionDispatch::Routing::RouteSet.new.tap do |r|
          r.draw do
            resources :dummys, as: resource_as, module: resource_module, path: resource_path, only: %i[index]
          end
        end
      end

      after do
        self.routes = @orig_routes
        @orig_routes = nil
      end

      before { get :index, params: { workbench_id: workbench.id } }

      context 'when workbench has some organisation as user' do
        let(:workbench) { context.workbench(:organisation_workbench) }

        it 'should succeed' do
          expect(response).to have_http_status(:ok)
        end
      end

      context 'when workbench is shared with user' do
        let(:workbench) { context.workbench(:shared_with_user_workbench) }

        it 'should succeed' do
          expect(response).to have_http_status(:ok)
        end
      end

      context "when workbench is shared with user's organisation" do
        let(:workbench) { context.workbench(:shared_with_organisation_workbench) }

        it 'should succeed' do
          expect(response).to have_http_status(:ok)
        end
      end

      context 'with unrelated workbench' do
        let(:workbench) { context.workbench(:other_workbench) }

        it 'should respond with NOT FOUND' do
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end
end
