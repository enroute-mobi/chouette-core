# frozen_string_literal: true

describe Chouette::ReferentialController, type: :controller do
  describe '#current_workbench' do
    # NOTE: controller do; end should be enough but inherited-resources requires a named class
    # so we have to define a temporary named class and manually define routes

    # rubocop:disable Lint/ConstantDefinitionInBlock,Style/ClassAndModuleChildren
    class self::DummysController < described_class
      def index
        render plain: "#{referential.id} #{current_workbench&.id}"
      end
    end
    # rubocop:enable Lint/ConstantDefinitionInBlock,Style/ClassAndModuleChildren

    describe self::DummysController, type: :controller do
      login_user

      let(:context) do
        Chouette.create do
          workgroup do
            workbench(:organisation_workbench, organisation: Organisation.find_by(code: 'first')) do
              referential :organisation_referential, organisation: Organisation.find_by(code: 'first')
            end
            workbench do
              referential :through_workgroup_referential
            end
          end
          workgroup do
            workbench do
              referential :other_referential
            end
          end
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

      let(:expected_workbench) { context.workbench(:organisation_workbench) }

      before { get :index, params: { referential_id: referential.id } }

      context 'when the referential workbench has the same organisation as user' do
        let(:referential) { context.referential(:organisation_referential) }

        it 'should return the id of the workbench having the same organisation as the user' do
          expect(response.body).to eq("#{referential.id} #{expected_workbench.id}")
        end
      end

      context 'when the referential workbench has a different organisation from user' do
        let(:referential) { context.referential(:through_workgroup_referential) }

        it 'should return the id of the workbench having the same organisation as the user' do
          expect(response.body).to eq("#{referential.id} #{expected_workbench.id}")
        end
      end

      context 'when the referential is unrelated to user organisation' do
        let(:referential) { context.referential(:other_referential) }

        it 'should respond with NOT FOUND' do
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end
end
