class Api::V1::WorkbenchController < ActionController::Base
  respond_to :json

  layout false
  before_action :authenticate

  private

  def authenticate
    auth_method = ActionController::HttpAuthentication::Basic.auth_scheme(request).downcase.to_sym
    if (auth_method == :basic)
      authenticate_or_request_with_http_basic do |username, password|
        api_key = ApiKey.find_by token: password
        workbench = api_key&.workbench
        @current_workbench = (workbench && workbench.organisation.code == username && (params[:workbench_id] ? workbench.id.to_s == params[:workbench_id] : true)) ? workbench : nil
        @current_workgroup = @current_workbench&.workgroup
        @current_workbench.present?
      end
    elsif (auth_method == :token)
      authenticate_or_request_with_http_token do |token|
        api_key = ApiKey.find_by token: token
        workbench = api_key&.workbench
        @current_workbench = (workbench && (params[:workbench_id] ? workbench.id.to_s == params[:workbench_id] : true)) ? workbench : nil
        @current_workgroup = @current_workbench&.workgroup
        @current_workgroup.present?
      end
    else
      # Render a 401 http error
      ActionController::HttpAuthentication::Token.authentication_request(self, "Application")
    end
  end

end
