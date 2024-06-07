# frozen_string_literal: true

ChouetteIhm::Application.routes.draw do # rubocop:disable Metrics/BlockLength
  resource :dashboard, only: :show
  resource :subscriptions, only: :create

  # Used to the redirect user to the current workbench
  # See CHOUETTE-797
  namespace :redirect do
    resources :lines, only: :show
    resources :companies, only: :show
    resources :stop_areas, only: :show
  end

  resources :workbenches, only: %i[show] do # rubocop:disable Metrics/BlockLength
    resources :api_keys

    resources :autocomplete, only: [] do
      get :lines, on: :collection, defaults: { format: 'json' }
      get :companies, on: :collection, defaults: { format: 'json' }
      get :line_providers, on: :collection, defaults: { format: 'json' }
      get :line_notices, on: :collection, defaults: { format: 'json' }
      get :stop_areas, on: :collection, defaults: { format: 'json' }
      get :parent_stop_areas, on: :collection, defaults: { format: 'json' }
      get :stop_area_providers, on: :collection, defaults: { format: 'json' }
      get :users, on: :collection, defaults: { format: 'json' }
      get :macro_lists, on: :collection, defaults: { format: 'json' }
      get :control_lists, on: :collection, defaults: { format: 'json' }
      get :calendars, on: :collection, defaults: { format: 'json' }
    end

    resource :output, controller: :workbench_outputs
    resources :merges do
      member do
        put :rollback
      end
      collection do
        get :available_referentials
      end
    end

    delete :referentials, on: :member, action: :delete_referentials
    resources :referentials do # rubocop:disable Metrics/BlockLength
      resources :autocomplete, controller: 'referential_autocomplete', only: [] do
        defaults format: :json do
          collection do
            get :companies
            get :lines
            get :journey_patterns
            get :time_tables
            get :vehicle_journeys
          end
        end
      end

      member do
        put :archive
        put :unarchive
        get :journey_patterns
      end

      resources :autocomplete, only: [] do
        get :line_providers, on: :collection, defaults: { format: 'json' }
        get :stop_areas, on: :collection, defaults: { format: 'json' }
        get :parent_stop_areas, on: :collection, defaults: { format: 'json' }
        get :stop_area_providers, on: :collection, defaults: { format: 'json' }
      end

      resources :lines, controller: 'referential_lines', only: %i[show] do # rubocop:disable Metrics/BlockLength
        resources :footnotes do
          collection do
            get 'edit_all'
            patch 'update_all'
          end
        end

        resources :routes do # rubocop:disable Metrics/BlockLength
          member do
            get 'edit_boarding_alighting'
            put 'save_boarding_alighting'
            get 'costs'
            post 'duplicate', to: 'routes#duplicate'
            get 'retrieve_nearby_stop_areas'
            get 'autocomplete_stop_areas'
          end
          collection do
            get 'fetch_opposite_routes'
            get 'fetch_user_permissions'
          end
          resource :journey_patterns, only: %i[show update], controller: :journey_patterns_collections
          resources :journey_patterns, only: [] do
            member do
              get 'available_specific_stop_places'
              put 'unassociate_shape'
              put 'duplicate'
            end

            resource :shapes, except: :index, module: 'journey_pattern' do
              collection do
                defaults format: :json do
                  get :get_user_permissions
                  put :update_line
                end
              end
            end
          end
        end
        resources :routing_constraint_zones
      end

      resources :routes, only: [] do
        resource :vehicle_journeys, only: %i[show update], controller: :route_vehicle_journeys
      end

      resources :vehicle_journeys, controller: 'referential_vehicle_journeys', only: [:index]

      resources :time_tables do
        member do
          post 'actualize'
          get 'duplicate'
          get 'month', defaults: { format: :json }
        end
      end
      resources :clean_ups

      scope module: 'redirect', only: :show do
        resources :routes
        resources :journey_patterns
        resources :vehicle_journeys
      end
    end

    resources :notification_rules
    resources :macro_lists do
      resources :macro_list_runs, only: %w[new create]
    end

    resources :sources do
      post :retrieve, on: :member
    end

    concern :macro_runs do
      resources :macro_runs, only: [] do
        resources :macro_messages, only: :index
      end
    end

    resources :macro_list_runs, only: %w[new create show index], concerns: :macro_runs do
      resources :macro_context_runs, only: [], concerns: :macro_runs
    end

    resources :control_lists do
      resources :control_list_runs, only: %w[new create]
    end

    concern :control_runs do
      resources :control_runs, only: [] do
        resources :control_messages, only: :index
      end
    end

    resources :control_list_runs, only: %w[new create show index], concerns: :control_runs do
      resources :control_context_runs, only: [], concerns: :control_runs
    end

    resource :stop_area_referential, only: %i[show edit update] do
      resources :searches, only: %i[index show create update destroy], path: ':parent_resources/searches'

      resources :stop_area_routing_constraints
      resources :entrances

      resources :stop_area_providers

      resources :stop_areas do
        get :autocomplete, on: :collection
        get :fetch_connection_links, on: :member, defaults: { format: 'geojson' }

        resources :document_memberships, only: %i[index create destroy], controller: :stop_area_document_memberships
      end

      resources :autocomplete, only: [] do
        get :stop_areas, on: :collection, defaults: { format: 'json' }
        get :parent_stop_areas, on: :collection, defaults: { format: 'json' }
        get :stop_area_providers, on: :collection, defaults: { format: 'json' }
      end
      resources :connection_links do
        get :get_connection_speeds, on: :collection, defaults: { format: 'json' }
      end
    end

    resource :line_referential, only: %i[show] do
      resources :searches, only: %i[index show create update destroy], path: ':parent_resources/searches'
      resources :line_routing_constraint_zones

      resources :line_providers

      resources :lines do
        get :autocomplete, on: :collection

        resources :line_notice_memberships, only: %i[index new create destroy]
        get 'line_notice_memberships/edit', to: 'line_notice_memberships_collections#edit'
        patch 'line_notice_memberships', to: 'line_notice_memberships_collections#update'

        resources :document_memberships, only: %i[index create destroy], controller: :line_document_memberships
      end

      resources :companies do
        get :autocomplete, on: :collection

        resources :document_memberships, only: %i[index create destroy], controller: :company_document_memberships
      end

      resources :networks
      resources :line_notices
    end

    resource :shape_referential, only: [] do
      resources :shapes, except: [:create]
      resources :point_of_interests
      resources :point_of_interest_categories
      resources :service_facility_sets
      resources :accessibility_assessments
    end

    resources :contracts

    resources :sequences

    resources :documents do
      get :download, on: :member
    end

    resources :document_providers

    resources :fare_zones
    resources :fare_providers

    resources :processing_rules, as: 'processing_rule_workbenches'

    resources :calendars do
      member do
        get 'month', defaults: { format: :json }
      end
    end

    resources :imports do
      get :download, on: :member
      get :internal_download, on: :member
    end
    get 'imports/:id/import_resources/:import_resource_id/messages',
        to: 'imports#messages',
        as: 'import_import_resource_import_messages'

    resources :exports do
      get :download, on: :member
    end
  end

  resource :workbench_confirmation, only: %i[new create]

  resources :workgroups, except: [:destroy] do # rubocop:disable Metrics/BlockLength
    put :setup_deletion, on: :member
    put :remove_deletion, on: :member

    member do
      get :edit_aggregate
      get :edit_merge
      get :edit_transport_modes
    end

    resources :code_spaces, except: :destroy

    resources :document_types
    resources :processing_rules, as: 'processing_rule_workgroups', controller: 'workgroup_processing_rules'

    resources :workbenches, controller: :workgroup_workbenches, only: %i[new create show edit update] do
      resources :sharings, controller: 'workbench/sharings', only: %i[new create destroy]
    end

    resource :output, controller: :workgroup_outputs
    resources :aggregates do
      member do
        put :rollback
      end
    end

    resources :publication_setups do
      resources :publications, only: [:create, :show]
    end

    resources :publication_apis do
      resources :publication_api_keys
    end

    resources :control_list_runs, controller: :workgroup_control_list_runs, only: %w[show index] do
      resources :control_runs, only: [] do
        resources :control_messages, controller: :workgroup_control_messages, only: :index
      end
    end

    resources :autocomplete, only: [] do
      get :lines, on: :collection, defaults: { format: 'json' }
      get :companies, on: :collection, defaults: { format: 'json' }
      get :line_providers, on: :collection, defaults: { format: 'json' }
      get :stop_areas, on: :collection, defaults: { format: 'json' }
      get :parent_stop_areas, on: :collection, defaults: { format: 'json' }
      get :stop_area_providers, on: :collection, defaults: { format: 'json' }
      get :shapes, on: :collection, defaults: { format: 'json' }
    end

    resources :imports, only: %i[index show], controller: :workgroup_imports do
      get :download, on: :member
    end
    get 'imports/:id/import_resources/:import_resource_id/messages',
        to: 'workgroup_imports#messages',
        as: 'import_import_resource_import_messages'

    resources :exports, only: %i[index show], controller: :workgroup_exports do
      get :download, on: :member
    end
  end

  devise_for :users, controllers: {
    confirmations: 'users/confirmations',
    invitations: 'users/invitations',
    passwords: 'users/passwords',
    registrations: 'users/registrations',
    saml_sessions: 'users/saml_sessions',
    sessions: 'users/sessions'
  }
  devise_scope :user do
    get '/users/saml/sign_in/:organisation_code',
        to: 'users/saml_sessions#new',
        as: 'organisation_code_new_saml_user_session'
    get '/users/saml/metadata/:organisation_code',
        to: 'users/saml_sessions#metadata',
        as: 'organisation_code_metadata_user_session'
  end

  devise_scope :user do
    authenticated :user do
      root to: 'dashboards#show'
    end

    unauthenticated :user do
      target = 'users/sessions#new'

      target = 'devise/cas_sessions#new' if Rails.application.config.chouette_authentication_settings[:type] == 'cas'

      root to: target
    end
  end

  namespace :api do # rubocop:disable Metrics/BlockLength
    namespace :v1 do # rubocop:disable Metrics/BlockLength
      get 'datas/:slug', to: 'datas#infos', as: :infos

      # Don't move after get 'datas/:slug/*key' CHOUETTE-1105
      get 'datas/:slug/lines', to: 'datas#lines', as: :lines

      get 'datas/:slug/documents/lines/:registration_number/:document_type',
        to: redirect('/api/v1/datas/%{slug}/lines/%{registration_number}/documents/%{document_type}')

      get 'datas/:slug/lines/:registration_number/documents/:document_type', to: 'publication_api/documents#show', resources: "lines"
      get 'datas/:slug/stop_areas/:registration_number/documents/:document_type', to: 'publication_api/documents#show', resources: "stop_areas"
      get 'datas/:slug/companies/:registration_number/documents/:document_type', to: 'publication_api/documents#show', resources: "companies"

      post 'datas/:slug/graphql', to: 'datas#graphql', as: :graphql

      get 'datas/:slug/*key', to: 'datas#download', format: false
      get 'datas/:slug.*key', to: 'datas#redirect', format: false

      resources :workbenches, only: [] do
        resources :imports, only: %i[index show create]
        resources :documents, only: [:create]
        member do
          post 'stop_area_referential/webhook', to: 'stop_area_referentials#webhook'
          post 'line_referential/webhook', to: 'line_referentials#webhook'
        end
      end

      get 'browser_environment', to: 'browser_environment#show', defaults: { format: 'json' }

      namespace :internals do
        resources :netex_imports, only: :create do
          member do
            get :notify_parent
            get :download
          end
        end
      end
    end
  end

  resource :organisation, only: %i[show edit update] do
    resources :users do
      member do
        put :block
        put :unblock
        put :reinvite
        put :reset_password
      end

      collection do
        get :new_invitation
        post :invite
      end
    end
  end

  mount LetterOpenerWeb::Engine, at: '/letter_opener' if %i[letter_opener_web
                                                            letter_opener].include?(Rails.application.config.action_mailer.delivery_method)

  get '/snap' => 'snapshots#show' if Rails.env.development? || Rails.env.test?

  mount Coverband::Reporters::Web.new, at: '/coverband' if ENV['COVERBAND_REDIS_URL'].present?
  mount GraphiQL::Rails::Engine, at: '/graphiql', graphql_path: '/graphql' if Rails.env.development?

  match '/404', to: 'errors#not_found', via: :all, as: 'not_found'
  match '/403', to: 'errors#forbidden', via: :all, as: 'forbidden'
  match '/422', to: 'errors#server_error', via: :all, as: 'unprocessable_entity'
  match '/500', to: 'errors#server_error', via: :all, as: 'server_error'
end
