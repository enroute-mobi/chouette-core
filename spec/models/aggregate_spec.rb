require 'rails_helper'

RSpec.describe Aggregate, type: :model do
  context "with another concurent aggregate" do
    before do
       Aggregate.create(workgroup: referential.workbench.workgroup, referentials: [referential, referential])
    end

    it "should not be valid" do
      aggregate = Aggregate.new(workgroup: referential.workbench.workgroup, referentials: [referential, referential])
      expect(aggregate).to_not be_valid
    end
  end

  it "should clean previous aggregates" do
    3.times do
      other_workbench = create(:workbench)
      other_referential = create(:referential, workbench: other_workbench, organisation: other_workbench.organisation)
      a = Aggregate.create!(workgroup: other_workbench.workgroup, referentials: [other_referential])
      a.update status: :successful
      a = Aggregate.create!(workgroup: referential.workbench.workgroup, referentials: [referential, referential])
      a.update status: :successful
      a = Aggregate.create!(workgroup: referential.workbench.workgroup, referentials: [referential, referential])
      a.update status: :failed
    end
    expect(Aggregate.count).to eq 9
    Aggregate.keep_operations = 2
    Aggregate.last.clean_previous_operations
    expect(Aggregate.count).to eq 8
  end
end