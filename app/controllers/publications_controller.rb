class PublicationsController < ChouetteController
  include PolicyChecker

  defaults :resource_class => Publication
  belongs_to :workgroup do
    belongs_to :publication_setup
  end

  respond_to :html

  before_action :decorate_exports, only: :show

  private
  
  def decorate_exports
    @exports = ExportDecorator.decorate(
      @publication.exports,
      context: {
        parent: @workgroup
      }
    )
  end
end
