module OperationsHelper
  # WARNING : This method should not be used anymore and we should use the new one below operation_user_status
  def operation_status(status, verbose: false, default_status: nil, i18n_prefix: nil)
    status = status.status if status.respond_to?(:status)
    status ||= default_status
    return unless status
    i18n_prefix ||= "operation_support.statuses"
    status = status.to_s.downcase

    txt = "#{i18n_prefix}.#{status}".t(fallback: "")
    title = verbose ? nil : txt

    out = if %w[new running pending].include? status
      render_icon "fa fa-clock #{status}", title
    else
      cls = ''
      cls = 'success' if status == 'successful'
      cls = 'success' if status == 'ok'
      cls = 'warning' if status == 'warning'
      cls = 'disabled' if status == 'canceled'
      cls = 'danger' if %w[failed aborted error].include? status

      render_icon "fa fa-circle text-#{cls}", title
    end
    if verbose
      out += content_tag :span , txt
    end
    out
  end

  def operation_user_status(operation)
    UserStatusRenderer.new(operation.user_status).render if operation
  end

  # Render a Operation#user_status with icon (and text)
  class UserStatusRenderer
    attr_reader :user_status

    include IconHelper
    include ActionView::Helpers::TagHelper

    def initialize(user_status)
      @user_status = user_status
    end

    delegate :text, to: :user_status

    def icon
      render_icon "fa #{icon_class}", text
    end

    def pending?
      user_status == 'pending'
    end

    mattr_reader :icon_text_classes, default: {
      'successful' => 'success',
      'warning' => 'warning',
      'failed' => 'danger'
    }

    def icon_text_class
      icon_text_classes[user_status]
    end

    def icon_class
      if pending?
        "fa-clock #{user_status}"
      else
        "fa-circle text-#{icon_text_class}"
      end
    end

    def render
      icon + content_tag(:span, text)
    end
  end

  def processing_helper(object)
    content_tag :div, class: "col-lg-6 col-md-6 col-sm-12 col-xs-12" do
      simple_block_for object, title: I18n.t("simple_block_for.title.processing") do |b|
        content = b.attribute :created_at, as: :datetime
        content += b.attribute :creator if object.respond_to?(:creator)
        content += b.attribute :started_at, as: :datetime
        content += b.attribute :ended_at, as: :datetime
        content += b.attribute :duration, value: object.ended_at.presence && object.started_at.presence && object.ended_at - object.started_at, as: :duration
        content += b.attribute(:notification_target, as: :enumerize) if object.respond_to?(:notification_target)
        content
      end
    end
  end

  def duration_in_words(seconds)
    seconds > 60 ? "#{(seconds /  1.minute).round} min" : "#{seconds.round} sec"
  end
end
