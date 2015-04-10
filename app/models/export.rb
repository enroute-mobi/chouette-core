class Export
  extend Enumerize
  extend ActiveModel::Naming
  include ActiveModel::Model  
  
  attr_reader :datas

  def initialize(response)
    @datas = response
  end

  def report
    report_path = datas.links.select{ |link| link["rel"] == "action_report"}.first.href
    if report_path
      response = Ievkit.get(report_path)
      ExportReport.new(response)
    else
      raise Ievkit::Error("Impossible to access report path link for export")
    end
  end 

  def compliance_check
    compliance_check_path = datas.links.select{ |link| link["rel"] == "validation_report"}.first.href
    if compliance_check_path
      response = Ievkit.get(compliance_check_path)
      ComplianceCheck.new(response)
    else
      raise Ievkit::Error("Impossible to access compliance check path link for export")
    end
  end

  def delete
    delete_path =  datas.links.select{ |link| link["rel"] == "delete"}.first.href
    if delete_path
      Ievkit.delete(delete_path)
    else
      raise Ievkit::Error("Impossible to access delete path link for export")
    end
  end

  def cancel
    cancel_path = datas.links.select{ |link| link["rel"] == "cancel"}.first.href
    if cancel_path
      Ievkit.delete(cancel_path)
    else
      raise Ievkit::Error("Impossible to access cancel path link for export")
    end
  end
  
  def id
    datas.id
  end
  
  def status
    datas.status
  end
  
  def format
    datas.format
  end

  def filename
    datas.links.select{ |link| link["rel"] == "data"}.first.href.gsub( /\/.*\//, "" )
  end
  
  def filename_extension
    File.extname(filename) if filename
  end
  
  def percentage_progress
    if %w{created}.include? status
      0
    elsif %w{ terminated canceled aborted }.include? status
      100
    else
      20
    end
  end
  
  def referential_name
    datas.referential
  end
  
  def name
    datas.action_parameters.name
  end
  
  def user_name
    datas.action_parameters.user_name
  end

  def created_at?
    datas.created?
  end
  
  def created_at
    Time.at(datas.created.to_i / 1000) if created_at?
  end

  def updated_at?
    datas.updated?
  end
  
  def updated_at
    Time.at(datas.updated.to_i / 1000) if updated_at?
  end
end
