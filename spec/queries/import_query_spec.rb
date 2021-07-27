RSpec.describe ImportQuery do

  let(:subject) { ImportQuery.new(Import::Workbench.all) }

  describe "#statuses" do
    before :each do
      Import::Workbench.status.values.each do |status|
        create(:workbench_import).update_column :status, status
      end
    end

    it "should return imports with status new, running and pending" do
      expect(subject.statuses(['new', 'pending', 'running']).scope.count).to eq 3
    end

    it "should return imports with status successful" do
      expect(subject.statuses(['successful']).scope.count).to eq 1
    end

    it "should return imports with status warning" do
      expect(subject.statuses(['warning']).scope.count).to eq 1
    end

    it "should return imports with status failed, aborted and canceled" do
      expect(subject.statuses(['failed', 'aborted', 'canceled']).scope.count).to eq 3
    end

    it "should return all imports for all statuses" do
      expect(subject.statuses(['successful', 'new', 'pending', 'running', 'warning', 'failed', 'aborted', 'canceled']).scope.count).to eq 8
    end
  end

  describe "#workbench" do
    let(:first_workbench) { create(:workbench) }
    let(:second_workbench) { create(:workbench) }
    let(:first_import) { create(:workbench_import, workbench: first_workbench) }
    let(:second_import) { create(:workbench_import, workbench: second_workbench) }

    it "should return imports with the select workbench name" do
      expect(subject.workbench([first_workbench.id]).scope).to match_array([first_import])
    end
  end

  describe "#text" do
    let(:first_import) { create(:workbench_import, name: "First") }
    let(:second_import) { create(:workbench_import, name: "Second") }

    it "should return imports with the select import name First" do
      expect(subject.text("First").scope).to match_array([first_import])
    end
  end

end
