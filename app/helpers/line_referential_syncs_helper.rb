module LineReferentialSyncsHelper

  def last_line_ref_sync_message(line_ref_sync)
    line_ref_sync.line_referential_sync_messages.last
  end

  def line_referential_sync_created_at(line_ref_sync)
    l(line_ref_sync.ended_at, format: :short_with_time) if line_ref_sync.ended_at
  end

  def line_referential_sync_status(line_ref_sync)
    status =  line_ref_sync.status

    if %w[new pending].include? status
      content_tag :span, '', class: "fa fa-clock"
    else
      cls =''
      cls = 'success' if status == 'successful'
      cls = 'danger' if status == 'failed'

      content_tag :span, '', class: "fa fa-circle text-#{cls}"
    end
  end

  def line_referential_sync_message(line_ref_sync)
    last_line_ref_sync_message = last_line_ref_sync_message(line_ref_sync)
    data = last_line_ref_sync_message.message_attributes.symbolize_keys!
    data[:processing_time] = distance_of_time_in_words(data[:processing_time].to_i)
    t("line_referential_sync.message.#{last_line_ref_sync_message.message_key}", last_line_ref_sync_message.message_attributes.symbolize_keys!).html_safe
  end
end
