module Shapes
  class GenerateGeoJson < ApplicationService
		attr_reader :object

		def initialize(shape, journey_pattern)
			@object = shape.persisted? ? ShapeDecorator.new(shape, journey_pattern) : journey_pattern
		end

		def call
			Rabl::Renderer.new("#{object.model_name.plural}/show.geo", object, view_path: 'app/views', format: :json)
		end

		class ShapeDecorator < SimpleDelegator
			def initialize(shape, jp)
				super shape
				@journey_pattern = jp
			end

			def name
				super || @journey_pattern.published_name || ''
			end

			def waypoints
				collection = super
				collection =  geometry.points if collection.empty?

				collection.map { |i| WaypointDecorator.new(i) }
			end
		end

		class WaypointDecorator < SimpleDelegator
			def name
				super
			rescue
				''
			end

			def waypoint_type
				super
			rescue
				'waypoint'
			end
		end
	end
end
