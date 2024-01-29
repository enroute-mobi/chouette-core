# frozen_string_literal: true

class WorkgroupExportsController < Chouette::WorkgroupController
  include PolicyChecker
  include Downloadable

  def self.controller_path
    'exports'
  end

  defaults resource_class: Export::Base, collection_name: 'exports', instance_name: 'export'

  def show
    @export = resource.decorate(context: { parent: parent })
    respond_to do |format|
      format.html
      format.json do
        fragment = render_to_string(partial: 'exports/show', formats: :html)
        render json: { fragment: fragment }
      end
    end
  end

  # rubocop:disable Metrics/MethodLength
  def index
    index! do |format|
      format.html do
        @contextual_cols = []
        @contextual_cols << TableBuilderHelper::Column.new(
          key: :workbench,
          name: Workbench.ts.capitalize,
          attribute: proc { |n| n.workbench.name },
          link_to: lambda do |export|
            policy(export.workbench).show? ? export.workbench : nil
          end
        )
        @exports = decorate_collection(collection)
      end
    end
  end
  # rubocop:enable Metrics/MethodLength

  def download
    prepare_for_download resource
    send_file resource.file.path, filename: resource.user_file.name, type: resource.user_file.content_type
  end

  protected

  # rubocop:disable Naming/MemoizedInstanceVariableName
  def resource
    @export ||= parent.exports.find(params[:id])
  end
  # rubocop:enable Naming/MemoizedInstanceVariableName

  def scope
    parent.exports
  end

  def search
    @search ||= Search.from_params(params, workgroup: workgroup)
  end

  def collection
    @collection ||= search.search(scope)
  end

  def decorate_collection(exports)
    ExportDecorator.decorate(
      exports,
      context: {
        parent: parent
      }
    )
  end

  class Search < Search::Operation
    def query_class
      Query::Export
    end
  end
end
