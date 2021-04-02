module RefreshForm
  class ExportsController < ActionController::Base
    before_action :build_export

    def edit_type
      render partial: "exports/types/#{parsed_type}"
    end

    def edit_exported_lines
      exported_lines = params.require(:exported_lines)
      render(
        partial: "exports/options/#{exported_lines}",
        locals: { resource_name: resource_name }
      )
    end

    private

    def resource_name
      'exports'
    end

    def parsed_type
      type.demodulize.underscore
    end

    def type
      params.require(:type)
    end

    def build_export
      @export = Export::Base.new(type: type)
    end
  end
end