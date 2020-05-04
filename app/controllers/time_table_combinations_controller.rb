class TimeTableCombinationsController < ChouetteController
  include ReferentialSupport
  defaults :resource_class => TimeTableCombination
  belongs_to :referential do
    belongs_to :time_table, :parent_class => Chouette::TimeTable
  end

  # include PolicyChecker

  def new
    @combination = TimeTableCombination.new(source_id: parent.id)
    authorize @combination
    @combination.combined_type = 'time_table'
  end

  def create
    @combination = TimeTableCombination.new(params[:time_table_combination].merge(source_id: parent.id))
    authorize @combination
    @combination.valid? ? perform_combination : render(:new)
  end

  def perform_combination
    begin
      @time_table    = @combination.combine
      flash[:notice] = t('time_table_combinations.success')
      redirect_to referential_time_table_path(referential, @time_table)
    rescue => e
      Chouette::Safe.capture "TimeTableCombination failed", e

      flash[:notice] = e.message
      flash[:error]  = t('time_table_combinations.failure')
      render :new
    end
  end
end
