class CleanUpsController < ChouetteController
  include ReferentialSupport
  respond_to :html, :only => [:create]
  belongs_to :referential

  defaults :resource_class => CleanUp

  def create
    @clean_up = CleanUp.new(clean_up_params)
    @clean_up.referential = @referential
    if @clean_up.valid?
      @clean_up.save
    else
      flash[:alert] = @clean_up.errors.full_messages.join("<br/>")
    end
    redirect_to referential_path(@referential)
  end

  def clean_up_params
    params.require(:clean_up).permit(:date_type, :begin_date, :end_date)
  end
end
