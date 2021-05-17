module ErrorManagement

  def not_found
    respond_to do |format|
      format.html { render 'errors/not_found',   status: 404 }
      format.any  { render plain: 'Not Found',  status: 404 }
    end
  end

  def forbidden
    respond_to do |format|
      format.html { render 'errors/forbidden', status: 403 }
      format.any  { render plain: 'Access Denied',  status: 403 }
    end
  end

  def server_error
    respond_to do |format|
      format.html { render 'errors/server_error', status: 500 }
      format.any  { render plain: 'Internal Server Error',  status: 500 }
    end
  end

end
