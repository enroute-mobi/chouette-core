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
    end
  end
  # rubocop:enable Metrics/MethodLength

  protected

  def import_resource
    @import_resource ||= resource.resources.find(params[:import_resource_id])
  end

  def import_messages
    @import_messages ||= import_resource.messages
  end

  def messages_filename
    import_resource_basename = import_resource.name.gsub('.xml', '')
    date = Time.zone.now.strftime('%d-%m-%Y_%H-%M')
    "#{I18n.t('import_messages.import_errors')}_#{import_resource_basename}_#{date}.csv"
  end
end
