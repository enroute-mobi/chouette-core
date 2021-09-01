class ImportsController < ChouetteController
  include PolicyChecker
  skip_before_action :authenticate_user!, only: [:internal_download]
  defaults resource_class: Import::Base, collection_name: 'imports', instance_name: 'import'
  respond_to :json, :html

  def internal_download
    resource = Import::Base.find params[:id]
    if params[:token] == resource.token_download
      store_file_and_clean_cache(resource)
      send_file resource.file.path
    else
      user_not_authorized
    end
  end

  def download
    store_file_and_clean_cache(resource)
    send_file resource.file.path, filename: resource.user_file.name, type: resource.user_file.content_type
  end

  def show
    @import = resource.decorate(context: { parent: parent })
    respond_to do |format|
      format.html
      format.json do
        fragment = render_to_string(partial: "imports/#{@import.short_type}", formats: :html)
        render json: { fragment: fragment }
      end
    end
  end

  def index
    @statuses = %w(pending successful warning failed)
    index! do |format|
      format.html do
        # if collection.out_of_bounds?
        #   redirect_to params.merge(:page => 1)
        # end
        @contextual_cols = []
        @contextual_cols << if workbench
                              TableBuilderHelper::Column.new(key: :creator, attribute: 'creator')
                            else
                              TableBuilderHelper::Column.new(
                                key: :workbench,
                                name: Organisation.ts.capitalize,
                                attribute: proc { |n| n.workbench.organisation.name },
                                link_to: lambda do |import|
                                  policy(import.workbench).show? ? import.workbench : nil
                                end
                              )
                            end
        @imports = decorate_collection(collection)
      end
    end
  end

  protected

  def parent
    @parent ||= workgroup || workbench
  end

  def workbench
    return unless params[:workbench_id]

    @workbench ||= current_organisation&.workbenches&.find(params[:workbench_id])
  end

  def workgroup
    return unless params[:workgroup_id]

    @workgroup ||= current_organisation&.workgroups.owned&.find(params[:workgroup_id])
  end

  def resource
    @import ||= parent.imports.find(params[:id])
  end

  def build_resource
    @import ||= Import::Workbench.new(*resource_params) do |import|
      import.workbench = parent
      import.creator   = current_user.name
    end
  end

  def scope
    parent.imports.where(type: 'Import::Workbench')
  end

  def search
    @search ||= ImportSearch.new(scope, params || {})
  end
  delegate :collection, to: :search

  def import_params
    permitted_keys = %i(name file type referential_id notification_target)
    permitted_keys += Import::Workbench.options.keys
    import_params = params.require(:import).permit(permitted_keys)
    import_params[:user_id] ||= current_user.id
    import_params
  end

  def decorate_collection(imports)
    ImportDecorator.decorate(
      imports,
      context: {
        parent: parent
      }
    )
  end

  class ImportSearch < Search::Base
    # All search attributes
    attr_accessor :name, :dates
    attr_reader :workbench, :status, :start_date, :end_date

    # validates :status, inclusion: { in: %w(pending successful warning failed), allow_nil: true, allow_blank: true
    # enumerize :status, in: %w[pending successful warning failed], i18n_scope: "status", multiple: true, allow_blank: true

    def start_date=(start_date)
      @start_date = Date.parse(start_date) if start_date.present?
    end

    def end_date=(end_date)
      @end_date = Date.parse(end_date) if end_date.present?
    end

    def date_range
      from = start_date || -Float::INFINITY
      to = end_date || Float::INFINITY # Not have the last day with this code
      (from..to)
    end

    def workbench=(_workbench)
      # Use filter because rails form sends an empty string inside array [""]
      @workbench = _workbench.filter{ |value| value.present? }
    end

    def status=(_status)
      # Use filter because rails form sends an empty string inside array [""]
      @status = _status.filter{ |value| value.present? }
    end

    def collection
      if valid?
        query.order(order.to_hash).paginate(paginate)
      else
        scope.none
      end
    end

    def candidate_workbenches
      # How to retrieve protected method parent from ImportsController?
      # calling_object.parent.workbenches.joins(:organisation).order('organisations.name')
    end

    def query
      statuses = find_import_statuses(status)
      ImportQuery.new(scope).text(name).statuses(statuses).include_in_date_range(date_range).scope
    end

    # class Order
    #   # TODO: Attributes can only return values :asc, :desc or nil (for securiy reason)
    #   # Attributes can be set with "asc", :asc, 1 to have the :asc value
    #   # Attributes can be set with "desc", :desc, -1 to have the :desc value
    #   # Attributes can be set with nil, 0 to have the nil value
    #   #
    #   # These methods ensures that the sort attribute is supported and valid
    #   attr_accessor :name
    #
    #   def to_hash
    #     { name: name }.delete_if { |_, v| v.nil? }
    #   end
    # end
  end
end
