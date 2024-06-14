# frozen_string_literal: true

class PublicationsController < Chouette::WorkgroupController
  defaults :resource_class => Publication
  belongs_to :publication_setup

  respond_to :html

  def create
    referential = @workgroup.output.current

    @publication = publication_setup.publish(referential, creator: current_user.name)
    @publication.enqueue

    redirect_to workgroup_publication_setup_path(@workgroup, publication_setup)
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
  alias publication_setup parent
end
