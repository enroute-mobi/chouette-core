# frozen_string_literal: true

module ImportMessages
  extend ActiveSupport::Concern

  # rubocop:disable Metrics/MethodLength
  def messages
    respond_to do |format|
      format.csv do
        send_data(
          Import::MessageExport.new(import_messages: import_messages.warnings_or_errors).to_csv(
            col_sep: ';',
            quote_char: '"',
            force_quotes: true
          ),
          filename: messages_filename
        )
      end
      format.json do
        messages = import_messages.order(:id).paginate(page: params[:page], per_page: 15)
        html = render_to_string(
          partial: 'imports/import_resource_messages',
          locals: { messages: messages, facade: facade },
          formats: :html
        )
        render json: { html: html }
      end
    end
  end
  # rubocop:enable Metrics/MethodLength

  protected

  def import_resource
    @import_resource ||= if resource.is_a?(Import::Workbench)
      resource.children.first&.resources&.find(params[:import_resource_id])
    else
      resource.resources.find(params[:import_resource_id])
    end
  end

  def import_messages
    @import_messages ||= begin
      messages = import_resource.messages
      
      if params.dig(:search, :criticity).present?
        criticities = params[:search][:criticity].reject(&:blank?)
        messages = messages.where(criticity: criticities) if criticities.any?
      end
      
      messages
    end
  end

  def messages_filename
    import_resource_basename = import_resource.name.gsub('.xml', '')
    date = Time.zone.now.strftime('%d-%m-%Y_%H-%M')
    "#{I18n.t('import_messages.import_errors')}_#{import_resource_basename}_#{date}.csv"
  end
end
