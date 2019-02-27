ChouetteIhm::Application.routes.draw do
  resource :dashboard
  resource :subscriptions, only: :create

  resources :exports, only: :upload do
    post :upload, on: :member, controller: :export_uploads
  end

  concern :iev_interfaces do
    resources :imports do
      get :download, on: :member
      resources :import_resources, only: [:index, :show] do
        resources :import_messages, only: [:index]
      end
    end
  end

  resources :workbenches, except: [:destroy], concerns: :iev_interfaces do
    delete :referentials, on: :member, action: :delete_referentials
    resources :api_keys

    resources :exports do
      post :upload, on: :member
    end

    resources :compliance_check_sets, only: [:index, :show] do
      get :executed, on: :member
      resources :compliance_checks, only: [:show]
      resources :compliance_check_messages, only: [:index]
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

    resources :referentials, only: %w(new create)
  end

  resources :workgroups, concerns: :iev_interfaces do
    member do
      get :edit_aggregate
      get :edit_controls
      put :update_controls
      get :edit_hole_sentinel
    end
    resources :compliance_check_sets, only: [:index, :show]
    resource :output, controller: :workgroup_outputs
    resources :aggregates do
      member do
        put :rollback
      end
    end

    resources :publication_setups do
      resources :publications, only: :show do
        resources :exports, only: :show
      end
    end

    resources :publication_apis do
      resources :publication_api_keys
    end

    resources :calendars do
      get :autocomplete, on: :collection, controller: 'autocomplete_calendars'
      member do
        get 'month', defaults: { format: :json }
      end
    end
  end

  resources :referentials, except: %w(new create index) do

    member do
      put :archive
      put :unarchive
      get :select_compliance_control_set
      post :validate
    end

    resources :autocomplete_stop_areas, only: [:show, :index] do
      get 'around', on: :member
    end
    resources :autocomplete_purchase_windows, only: [:index]
    resources :autocomplete_time_tables, only: [:index]

    match 'lines' => 'lines#destroy_all', :via => :delete
    resources :lines, controller: "referential_lines", except: :index do
      get :autocomplete, on: :collection, to: 'autocomplete_lines#index'

      resources :footnotes do
        collection do
          get 'edit_all'
          patch 'update_all'
        end
      end
      delete :index, on: :collection, action: :delete_all
      collection do
        get 'name_filter'
      end
      resources :routes do
        member do
          get 'edit_boarding_alighting'
          put 'save_boarding_alighting'
          get 'costs'
          post 'duplicate', to: 'routes#duplicate'
        end
        resource :journey_patterns_collection, :only => [:show, :update]
        resources :journey_patterns do
          get 'new_vehicle_journey', on: :member
        end
        resource :vehicle_journeys_collection, :only => [:show, :update]
        resources :vehicle_journeys, :vehicle_journey_frequencies do
          get 'select_journey_pattern', :on => :member
          get 'select_vehicle_journey', :on => :member
          resources :vehicle_translations
          resources :time_tables
        end
        resources :vehicle_journey_imports
        resources :vehicle_journey_exports
        resources :stop_points, only: :index, controller: 'route_stop_points'
      end
      resources :routing_constraint_zones
    end

    resources :vehicle_journeys, controller: 'referential_vehicle_journeys', only: [:index]

    resources :exports, :only => [:index, :show, :destroy]  do
      member do
        get "exported_file"
      end
    end

    resources :purchase_windows

    resources :time_tables do
      collection do
        get :tags
      end
      member do
        post 'actualize'
        get 'duplicate'
        get 'month', defaults: { format: :json }
      end
      resources :time_table_dates
      resources :time_table_periods
      resources :time_table_combinations
    end
    resources :clean_ups
  end

  devise_for :users, :controllers => {
    invitations: 'users/invitations',
    registrations: 'devise/sessions',
    passwords: 'users/passwords'
  }

  devise_scope :user do
    authenticated :user do
      root :to => 'workbenches#index', as: :authenticated_root
    end

    unauthenticated :user do
      target = 'devise/sessions#new'

      if Rails.application.config.chouette_authentication_settings[:type] == "cas"
        target = 'devise/cas_sessions#new'
      end

      root :to => target, as: :unauthenticated_root
    end
  end

  if SmartEnv.boolean "BYPASS_AUTH_FOR_SIDEKIQ"
    mount Sidekiq::Web => '/sidekiq'
    match "/delayed_job" => DelayedJobWeb, :anchor => false, :via => [:get, :post]
  else
    authenticate :user, lambda { |u| u.can_monitor_sidekiq? } do
      mount Sidekiq::Web => '/sidekiq'
      match "/delayed_job" => DelayedJobWeb, :anchor => false, :via => [:get, :post]
    end
  end

  namespace :api do
    namespace :v1 do
      get 'datas/:slug', to: 'datas#infos', as: :infos
      get 'datas/:slug.:key.zip', to: 'datas#download_full', as: :download_full
      get 'datas/:slug/lines/:line_id.:key.zip', to: 'datas#download_line', as: :download_line

      resources :workbenches, except: %i(destroy) do
        resources :imports, only: [:index, :show, :create]
      end

      namespace :internals do
        get 'compliance_check_sets/:id/notify_parent', to: 'compliance_check_sets#notify_parent'

        get 'netex_exports/:id/notify_parent', to: 'netex_exports#notify_parent'
        post 'netex_exports/:id/upload', to: 'netex_exports#upload'

        resources :netex_imports, only: :create do
          member do
            get :notify_parent
            get :download
          end
        end
      end
    end
  end

  resource :organisation, :only => [:show, :edit, :update] do
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

  resources :compliance_control_sets do
    get :simple, on: :member
    get :clone, on: :member
    resources :compliance_controls, except: :index do
      get :select_type, on: :collection
    end
    resources :compliance_control_blocks, :except => [:show, :index]
  end

  deactivable = Proc.new do
    put :deactivate, on: :member
    put :activate, on: :member
  end

  resources :stop_area_referentials, :only => [:show] do
    post :sync, on: :member
    resources :stop_area_providers do
      get :autocomplete, on: :collection
    end
    resources :stop_areas do
      put :deactivate, on: :member
      put :activate, on: :member
      get :autocomplete, on: :collection
    end
  end

  resources :line_referentials, :only => [:show, :edit, :update] do
    post :sync, on: :member
    resources :lines, &deactivable
    resources :group_of_lines
    resources :companies
    resources :networks
  end

  resources :companies do
    get :autocomplete, on: :collection, controller: 'autocomplete_companies'
  end

  resources :calendars do
    get :autocomplete, on: :collection, controller: 'autocomplete_calendars'
    member do
      get 'month', defaults: { format: :json }
    end
  end


  root :to => "dashboards#show"

  if Rails.env.development? || Rails.env.test?
    get "/snap" => "snapshots#show"
  end

  get '/help/(*slug)' => 'help#show'

  if Rails.application.config.development_toolbar
    post "/development_toolbar" => "development_toolbar#update_settings", as: :development_toolbar_update_settings
  end

  match '/404', to: 'errors#not_found', via: :all, as: 'not_found'
  match '/403', to: 'errors#forbidden', via: :all, as: 'forbidden'
  match '/422', to: 'errors#server_error', via: :all, as: 'unprocessable_entity'
  match '/500', to: 'errors#server_error', via: :all, as: 'server_error'

  match '/status', to: 'statuses#index', via: :get

end
