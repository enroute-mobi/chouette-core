# frozen_string_literal: true

describe Chouette::WorkgroupController, type: :controller do
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
          workgroup(:organisation_workgroup, owner: Organisation.find_by(code: 'first')) do
            workbench organisation: Organisation.find_by(code: 'first')
          end
          workgroup :workbench_workgroup do
            workbench organisation: Organisation.find_by(code: 'first')
          end
          workgroup(:other_workgroup)
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

      before { get :index, params: { workgroup_id: workgroup.id } }

      context 'when the workgroup owner is the user organisation' do
        let(:workgroup) { context.workgroup(:organisation_workgroup) }

        it 'should succeed' do
          expect(response).to have_http_status(:ok)
        end
      end

      context 'when the workgroup organisations contains the user organisation' do
        let(:workgroup) { context.workgroup(:workbench_workgroup) }

        it 'should respond with NOT FOUND' do
          expect(response).to have_http_status(:not_found)
        end
      end

      context 'when the workgroup is unrelated to user organisation' do
        let(:workgroup) { context.workgroup(:other_workgroup) }

        it 'should respond with NOT FOUND' do
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end
end
