module RefreshForm
  class PublicationSetupsController < ExportsController
    before_action :build_publication_setup

    def edit_type
      render partial: "publication_setups/edit_#{type.demodulize.underscore}"
    end

    private

    def build_publication_setup
      @publication_setup = PublicationSetup.new
    end

    def resource_name
      'publication_setups'
    end
  end
end