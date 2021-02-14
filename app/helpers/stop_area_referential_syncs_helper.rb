module StopAreaReferentialSyncsHelper

  def last_stop_area_ref_sync_message(stop_area_ref_sync)
    stop_area_ref_sync.stop_area_referential_sync_messages.last
  end

  def stop_area_referential_sync_created_at(stop_area_ref_sync)
    l(stop_area_ref_sync.ended_at, format: :short_with_time) if stop_area_ref_sync.ended_at
  end

  def stop_area_referential_sync_status(stop_area_ref_sync)
    status =  stop_area_ref_sync.status

    if %w[new pending].include? status
      content_tag :span, '', class: "fa fa-clock"
    else
      cls =''
      cls = 'success' if status == 'successful'
      cls = 'danger' if status == 'failed'

      content_tag :span, '', class: "fa fa-circle text-#{cls}"
    end
  end

  def stop_area_referential_sync_message(stop_area_ref_sync)
    last_stop_area_ref_sync_message = last_stop_area_ref_sync_message(stop_area_ref_sync)
    data = last_stop_area_ref_sync_message.message_attributes.symbolize_keys!
    data[:processing_time] = distance_of_time_in_words(data[:processing_time].to_i)
    t("stop_area_referential_sync.message.#{last_stop_area_ref_sync_message.message_key}", last_stop_area_ref_sync_message.message_attributes.symbolize_keys!).html_safe
  end
end
