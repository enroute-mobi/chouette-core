# frozen_string_literal: true

class ImportMessagesController < Chouette::WorkbenchController
  before_action :authorize_resource, except: %i[index]
  before_action :init_facade

  respond_to :html, :json

  helper_method :facade

  def index
    @messages = decorate_collection(collection)
    
    respond_to do |format|
      format.html
      format.json do
        html = render_to_string(partial: 'import_messages/messages', locals: { messages: @messages }, formats: :html)
        render json: { html: html }
      end
    end
  end

  private

  def parent
    @parent ||= workbench
  end

  def resource
    @import ||= parent.imports.find(params[:import_id])
  end

  def search
    @search ||= Search::ImportMessage.from_params(params, import: resource)
  end

  def collection
    @collection ||= search.search(scope)
  end

  def scope
    direct_message_ids = resource.messages.pluck(:id)
    resource_message_ids = Import::Message.where(resource_id: resource.resources.select(:id)).pluck(:id)
    all_message_ids = (direct_message_ids + resource_message_ids).uniq
    
    Import::Message.where(id: all_message_ids).includes(:resource)
  end

  def decorate_collection(messages)
    Import::MessageDecorator.decorate(
      messages,
      context: {
        import: resource,
        workbench: workbench
      }
    )
  end

  def init_facade
    @facade ||= OperationRunFacade.new(resource, current_workbench)
  end

  alias facade init_facade
end
