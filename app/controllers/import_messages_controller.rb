# frozen_string_literal: true

class ImportMessagesController < Chouette::WorkbenchController
  defaults resource_class: Import::Message, collection_name: 'messages'

  belongs_to :import

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

  def search
    @search ||= Search::ImportMessage.from_params(params, import: parent)
  end

  def collection
    @collection ||= search.search(scope)
  end

  def scope
    direct_messages = parent.messages
    import_messages = Import::Message.where(resource_id: parent.resources.select(:id))
    
    Import::Message.where(id: direct_messages).or(Import::Message.where(id: import_messages)).includes(:resource)
  end

  def decorate_collection(messages)
    Import::MessageDecorator.decorate(
      messages,
      context: {
        import: parent,
        workbench: workbench
      }
    )
  end

  def init_facade
    @facade ||= OperationRunFacade.new(parent, current_workbench)
  end

  alias facade init_facade
end
