# frozen_string_literal: true

class PublicationsController < Chouette::WorkgroupController
  defaults :resource_class => Publication
  belongs_to :publication_setup

  respond_to :html

  def create
    aggregate = @workgroup.aggregates.where(status: 'successful').last

    @publication = aggregate.publish_with_setup(parent)

    redirect_to workgroup_publication_setup_path(@workgroup, parent)
  end

  def show
    @export = ExportDecorator.decorate(
      publication.export,
      context: {
        parent: workgroup
      }
    )
    show!
  end

  alias publication resource

end
