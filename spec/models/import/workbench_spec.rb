require "rails_helper"

RSpec.describe Import::Workbench do

  let(:referential) do
    create :referential do |referential|
      referential.line_referential.objectid_format = "netex"
      referential.stop_area_referential.objectid_format = "netex"
    end
  end

  let(:workbench) do
    create :workbench do |workbench|
      workbench.line_referential.objectid_format = "netex"
      workbench.stop_area_referential.objectid_format = "netex"
    end
  end

  let(:options){
    {}
  }

  let(:import) {
    Import::Workbench.create workbench: workbench, name: "test", creator: "Albator", file: open_fixture("google-sample-feed.zip"), options: options
  }


  context "#done!" do
    it "should do nothing" do
      expect{import.done!}.to change{Merge.count}.by 0
    end

    context "when 'automatic_merge' is set'" do
      let(:options){
        {
          automatic_merge: "true"
        }
      }
      it "should do nothing" do
        expect{import.done!}.to change{Merge.count}.by 0
      end
    end

    context "when successful" do
      before(:each){ import.update status: :successful }

      it "should do nothing" do
        expect{import.done!}.to change{Merge.count}.by 0
      end

      context "when 'automatic_merge' is set'" do
        let(:options){
          {
            automatic_merge: "true"
          }
        }
        it "should create a Merge" do
          expect{import.done!}.to change{Merge.count}.by 1
          merge = Merge.last
          expect(merge.creator).to eq import.creator
          expect(merge.workbench).to eq import.workbench
          expect(merge.referentials).to eq import.resources.map(&:referential)
        end
      end
    end
  end

end
