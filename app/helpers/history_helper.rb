# frozen_string_literal: true

module HistoryHelper

  def history_tag(object)
    field_set_tag t("layouts.history_tag.title"), class: "history_tag" do
      content_tag :ul do
        [:created_at, :updated_at, :user_name, :no_save].each do |field|
          concat history_tag_li(object, field)
        end
      end
    end
  end

  protected

  def history_tag_li(object, field)
    if object.respond_to?(field)
      key = t("layouts.history_tag.#{field}")
      value = object.public_send(field)
      value = l(value) if value.is_a?(Time)
      value = t(value.to_s) if value.in?([true, false])
      content_tag(:li, "#{key} : #{value}")
    end
  end
end
