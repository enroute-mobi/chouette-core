module TransportModeFilter
  extend ActiveSupport::Concern

  included do
    before_action :set_transport_mode_and_submode, only: [:index]

    def ransack_transport_mode scope
      return scope unless params[:q].try(:[], :transport_mode) || params[:q].try(:[], :transport_submode)

      @transport_modes = params[:q][:transport_mode].keys  if params[:q].has_key?(:transport_mode)
      @transport_submodes = params[:q][:transport_submode].keys if params[:q].has_key?(:transport_submode)

      scope = scope.where(transport_mode: @transport_modes) unless @transport_modes.empty?
      scope = scope.where(transport_submode: @transport_submodes) unless @transport_submodes.empty?

      return scope
    end

    private

    def set_transport_mode_and_submode
      @transport_modes = @transport_submodes = []
    end
  end

end
