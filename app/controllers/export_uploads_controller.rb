class ExportUploadsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:upload]
  skip_before_action :verify_authenticity_token, only: [:upload]

  def upload
    resource = Export::Base.find params[:id]
    if params[:token] == resource.token_upload
      resource.file = params[:file]
      resource.save!
      render json: {status: :ok}
    else
      Rails.logger.error("Export token : #{resource.token_upload} is different from params token : #{params[:token]}")
      render json: {status: 'Unauthorized'},  status: 401
    end
  end
end
