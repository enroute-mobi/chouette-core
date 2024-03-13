# frozen_string_literal: true

module JourneyPattern
  class ShapesController < ::Chouette::ReferentialController
    include DefaultPathHelper
    
    defaults singleton: true, resource_class: Shape, instance_name: 'shape'

    belongs_to :referential
    belongs_to :line, parent_class: Chouette::Line
    belongs_to :route, parent_class: Chouette::Route
    belongs_to :journey_pattern, parent_class: Chouette::JourneyPattern

    def new
      if resource
        flash[:warning] = I18n.t('shapes.errors.cannot_create')
        return redirect_to edit_referential_line_route_journey_pattern_shapes_path(parents) 
      end

      respond_to do |format|
        format.html

        format.json do
          render json: Shapes::GenerateGeoJson.call(Shape.new, parent).render
        end
      end
    end

    def edit
      if !resource
        flash[:warning] = I18n.t('shapes.errors.cannot_edit')
        return redirect_to new_referential_line_route_journey_pattern_shapes_path(parents)
      end

      # if resource.waypoints.empty?
      #   flash[:warning] = I18n.t('shapes.errors.cannot_edit_imported_shape')
      #   return redirect_to new_referential_line_route_journey_pattern_shapes_path(parents)
      # end

      respond_to do |format|
        format.html

        format.json do
          render json: Shapes::GenerateGeoJson.call(resource, parent).render
        end
      end
    end

    def create
      @shape = Shapes::Create.call(**shape_params)
      
      create!(&create_or_update_callback)
    end

    def update
      @shape = Shapes::Update.call(**shape_params)
      
      update!(&create_or_update_callback)
    end

    def get_user_permissions
      shape = begin
        Shape.find(params[:shape_id])
      rescue ActiveRecord::RecordNotFound
        Shape.new(shape_provider: shape_provider)
      end

      policy = policy(shape)

      render json: {
        canCreate: policy.create?,
        canUpdate: policy.update?
      }
    end

    def update_line
      coordinates = JSON.parse(request.raw_post).fetch('coordinates')

      render json: TomTom::BuildLineStringFeature.call(coordinates)
    end

    private

    def create_or_update_callback
      return -> (success, failure) do
        success.json do
          response.set_header('Location', referential_line_route_journey_patterns_path(parents.first(3)))
          render json: {}, status: 201
        end

        failure.json do
          render json: { errors: @shape.errors.full_messages }, status: 400
        end
      end
    end

    def parents
      [ referential, parent.line, parent.route, parent ]
    end

    def payload
      JSON.parse(request.raw_post.presence || "{}")
    end

    def workbench
      @workbench ||= default_workbench(resource: parent.line)
    end

    def resource_params
      [{}] # Needed to avoid ActiveRecord::Mismatch error with update! since Shapes::Update is handling the update 
    end

    def shape_provider
      workbench.shape_providers.first
    end

    def shape_params
      ActionController::Parameters.new(payload).require(:shape).permit(:name).tap do |_params|
        _params[:shape_referential_id] = workbench.shape_referential.id
        _params[:shape_provider_id] = shape_provider.id
        _params[:waypoints] = payload.dig('shape', 'waypoints') || []
        _params[:coordinates] = payload.dig('shape', 'coordinates') || []

        _params[:journey_pattern] = parent
      end.to_h.symbolize_keys
    end
  end
end
