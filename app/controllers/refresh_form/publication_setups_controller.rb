module RefreshForm
  class PublicationSetupsController < ExportsController
    def edit_type
      render partial: "publication_setups/edit_#{type.demodulize.underscore}"
    end

    private

    def resource_name
      'publication_setup[export_options]'
    end
  end
end