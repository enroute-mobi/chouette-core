RSpec.describe StopAreasController, :type => :controller do
  login_user

  let!(:context) do
    Chouette.create do
      workgroup do
        workbench organisation: Organisation.find_by_code('first') do
          3.times { stop_area }
        end
      end
    end
  end

  let(:workbench) { context.workbench }
  let(:stop_area_referential) { context.stop_area_referential }
  let(:stop_area_provider) { context.stop_area_provider }
  let(:stop_area) { context.stop_area }

  describe "#search" do
    let(:scope) { double }
    subject(:search) { Search::StopArea.new scope }
  end
end
