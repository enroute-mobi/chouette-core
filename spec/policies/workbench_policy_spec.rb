RSpec.describe WorkbenchPolicy, type: :policy do

  let( :record ){ build_stubbed :workbench }

  permissions :create_stop_area_provider? do
    it "should not allow for destroy" do
      expect_it.not_to permit(user_context, record)
    end

    context "for the owner" do
      before do
        record.owner = user.organisation
      end

      it "should not allow for destroy" do
        expect_it.not_to permit(user_context, record)
      end
    end
  end


end
