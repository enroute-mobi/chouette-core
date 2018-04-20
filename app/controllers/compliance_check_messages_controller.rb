class ComplianceCheckMessagesController < ChouetteController
  defaults resource_class: ComplianceCheckMessage, collection_name: 'compliance_check_messages', instance_name: 'compliance_check_message'
  respond_to :csv
  belongs_to :compliance_check_set, :parent_class => ComplianceCheckSet


  def index
    index! do |format|
      format.csv {
        send_data ComplianceCheckMessageExport.new(compliance_check_messages: collection).to_csv(:col_sep => "\;", :quote_char=>'"', force_quotes: true, server_url: request.base_url) , :filename => "compliance_check_set_errors_#{line_code}_#{DateTime.now.to_s}.csv"
      }
    end
  end

  protected
  def collection
    parent.compliance_check_messages.where(compliance_check_resource_id: params[:compliance_check_resource_id])
  end

  def parent
    @compliance_check_set ||= ComplianceCheckSet.find(params[:compliance_check_set_id])
  end

  def compliance_check_resource
    ComplianceCheckResource.find(params[:compliance_check_resource_id]) 
  end

  private 

  def line_code
    Chouette::Line.find_by_objectid("#{compliance_check_resource.reference}").get_objectid.local_id
  end

end
