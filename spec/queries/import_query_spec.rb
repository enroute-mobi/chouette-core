RSpec.describe ImportQuery do

  let(:subject) { ImportQuery.new(Import::Workbench.all) }

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

  describe "#statuses" do
    before :each do
      Import::Workbench.status.values.each do |status|
        create(:workbench_import).update_column :status, status
      end
    end

    it "should return new and pending imports when status group pending is selected" do
      expect(subject.statuses(["pending"]).count).to eq 3
    end

    it "should return successful imports when status group successful is selected" do
      expect(subject.statuses(["successful"]).count).to eq 1
    end

    it "should return warning imports when status group warning is selected" do
      expect(subject.statuses(["warning"]).count).to eq 1
    end

    it "should return failed and aborted and canceled imports when status group failed is selected" do
      expect(subject.statuses(["failed"]).count).to eq 3
    end

    it "should return all imports when status group success, warning, pending and failed is selected" do
      expect(subject.statuses(["successful", "pending", "warning", "failed"]).count).to eq 8
    end
  end

end
