# frozen_string_literal: true

class OrganisationsController < Chouette::ResourceController

  defaults :resource_class => Organisation
  respond_to :html, :only => [:edit, :show, :update]

  def update
    update! do |success, failure|
      success.html { redirect_to organisation_path }
    end
  end

  def show
    show! do
      @q = @organisation.users.ransack(params[:q])
      @users = UserDecorator.decorate(
        @q.result.paginate(page: params[:page]).order(sort_params)
      )
    end
  end

  private

  def sort_column
    %w[name email].include?(params[:sort]) ? params[:sort] : 'name'
  end

  def sort_direction
    %w[asc desc].include?(params[:direction]) ?  params[:direction] : 'asc'
  end

  def sort_params
    "#{sort_column} #{sort_direction}"
  end

  def resource
    @organisation = current_organisation
  end

  def organisation_params
    params.require(:organisation).permit(:name)
  end
end
