class PublicationsController < ChouetteController
  include PolicyChecker

  defaults :resource_class => Publication
  belongs_to :workgroup do
    belongs_to :publication_setup
  end

  respond_to :html
end
