# frozen_string_literal: true

class CleanUpsController < Chouette::ReferentialController
  defaults :resource_class => CleanUp

  skip_before_action :authorize_resource_class

  def create
    create! do |success, _failure|
      success.html do
        redirect_to @referential
      end
    end
  end

  def new
    build_resource
    @clean_up.begin_date = @referential.metadatas_period.min
    @clean_up.end_date = @referential.metadatas_period.max
  end

  def get_data_cleanups
    data_cleanups_params.keys.select do |k|
      data_cleanups_params[k] == 'true'
    end
  end

  def data_cleanups_params
     params.require(:data_cleanups).permit(CleanUp.data_cleanups.values)
  end

  def clean_up_params
    clean_up_params = params.require(:clean_up).permit(:date_type, :begin_date, :end_date).to_h.update(data_cleanups: get_data_cleanups)
    if clean_up_params[:date_type] == 'outside'
      clean_up_params.delete 'begin_date(3i)'
      clean_up_params.delete 'begin_date(2i)'
      clean_up_params.delete 'begin_date(1i)'
      clean_up_params.delete 'end_date(3i)'
      clean_up_params.delete 'end_date(2i)'
      clean_up_params.delete 'end_date(1i)'
      clean_up_params[:begin_date] = @referential.metadatas_period.min
      clean_up_params[:end_date] = @referential.metadatas_period.max
    end
    pp clean_up_params
  end

  def begin_of_association_chain
    nil
  end

  Policy::Authorizer::Controller.for(self, Policy::Authorizer::Legacy)
end
