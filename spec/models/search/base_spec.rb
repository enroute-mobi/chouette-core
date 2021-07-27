RSpec.describe Search::Base, :type => :model do

  let(:subject) { Search::Base.new(Import::Workbench.all) }

  describe "#find_import_statuses" do

    it "should return new and pending status for import when status group pending is selected" do
      expect(subject.find_import_statuses(["pending"])).to match_array(['new', 'pending', 'running'])
    end

    it "should return successful status for import when status group successful is selected" do
      expect(subject.find_import_statuses(["successful"])).to match_array(['successful'])
    end

    it "should return warning status for import when status group warning is selected" do
      expect(subject.find_import_statuses(["warning"])).to match_array(['warning'])
    end

    it "should return failed and aborted and canceled status for import when status group failed is selected" do
      expect(subject.find_import_statuses(["failed"])).to match_array(['failed', 'aborted', 'canceled'])
    end

    it "should return all statuses for import when status group successful, warning, pending and failed is selected" do
      expect(subject.find_import_statuses(["successful", "pending", "warning", "failed"])).to match_array(['successful', 'warning', 'new', 'pending', 'running', 'failed', 'aborted', 'canceled'])
    end
  end
end
