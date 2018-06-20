class PurchaseWindowsController < ChouetteController
  include ReferentialSupport
  include RansackDateFilter
  include PolicyChecker
  before_action :ransack_contains_date, only: [:index]
  defaults :resource_class => Chouette::PurchaseWindow, collection_name: 'purchase_windows', instance_name: 'purchase_window'
  belongs_to :referential

  requires_feature :purchase_windows

  def index
    index! do
      @purchase_windows = decorate_purchase_windows(@purchase_windows)
    end
  end

  def show
    show! do
      @purchase_window = @purchase_window.decorate(context: {
        referential: @referential
      })
    end
  end

  protected

  def create_resource(purchase_window)
    super
  end

  private

  def purchase_window_params
    params.require(:purchase_window).permit(:id, :name, :color, :referential_id, periods_attributes: [:id, :begin, :end, :_destroy])
  end

  def decorate_purchase_windows(purchase_windows)
    PurchaseWindowDecorator.decorate(
      purchase_windows,
      context: {
        referential: @referential
      }
    )
  end

   def sort_column
    Chouette::PurchaseWindow.column_names.include?(params[:sort]) ? params[:sort] : 'name'
  end

  def sort_direction
    %w[asc desc].include?(params[:direction]) ?  params[:direction] : 'asc'
  end

  def collection
    return @purchase_windows if @purchase_windows
    @q = Chouette::PurchaseWindow.ransack(params[:q])

    purchase_windows = @q.result
    purchase_windows = purchase_windows.order(sort_column + ' ' + sort_direction) if sort_column && sort_direction
    @purchase_windows = purchase_windows.paginate(page: params[:page])
  end

  def ransack_contains_date
    date =[]
    if params[:q] && params[:q]['contains_date'].present?
      params[:q]['contains_date'] = @date = params[:q]['contains_date'].to_date
    elsif params[:q] && params[:q]['contains_date(1i)'].present?
      ['contains_date(1i)', 'contains_date(2i)', 'contains_date(3i)'].each do |key|
        date << params[:q][key].to_i
        params[:q].delete(key)
      end
      params[:q]['contains_date'] = @date = Date.new(*date) rescue nil
    end
  end
end
