# frozen_string_literal: true

module ExportSetupDecorator
  extend ActiveSupport::Concern

  prepended do # rubocop:disable Metrics/BlockLength
    define_instance_method :display_profile_options do
      export_setup.profile_options.map { |k, v| "#{k} : #{v}" }.join(', ')
    end

    define_instance_method :display_period do
      period = export_setup.scope_setup.vehicle_journeys.period
      case period
      when ::Export::Setup::Scope::PeriodSelector::Duration
        "#{::Export::Setup::Scope::PeriodSelector::Duration.model_name.human} :  #{period.day_count}"
      when ::Export::Setup::Scope::PeriodSelector::Static
        "#{I18n.l(period.from, format: :default)} - #{I18n.l(period.to, format: :default)}"
      else # ::Export::Setup::Scope::PeriodSelector::All
        ::Export::Setup::Scope::PeriodSelector::All.model_name.human
      end
    end

    define_instance_method :alpine_state do
      {
        type: export_type || 'Export::Gtfs',
        exportedLines: form_export_setup.scope_setup.vehicle_journeys.included_lines.type,
        period: form_export_setup.scope_setup.vehicle_journeys.period.type,
        profileOptions: form_export_setup.try(:profile_options)
      }
    end

    define_instance_method :export_type do
      raise NotImplementedError
    end

    define_instance_method :export_setup_method_name do
      raise NotImplementedError
    end

    define_instance_method :export_setup do
      object.send(export_setup_method_name)
    end

    define_instance_method :form_export_setup do
      return @form_export_setup if @form_export_setup

      form_export_setup = export_setup
      unless form_export_setup
        form_export_setup = ::Export::Setup::Base.new
        form_export_setup.parent = object
      end
      form_export_setup.scope_setup ||= form_export_setup.candidate_scope_setup_classes.first.new
      @form_export_setup = form_export_setup
    end
  end
end
