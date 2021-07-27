class JourneyPatternsController < ChouetteController
  include ReferentialSupport
  defaults :resource_class => Chouette::JourneyPattern

  respond_to :kml, :only => :show

  belongs_to :referential do
    belongs_to :line, :parent_class => Chouette::Line do
      belongs_to :route, :parent_class => Chouette::Route
    end
  end

  include PolicyChecker

end
