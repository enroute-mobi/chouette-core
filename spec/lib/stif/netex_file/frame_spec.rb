RSpec.describe Stif::NetexFile::Frame do
  
  context "line object id extraction" do
    it "gets the line object id if frame describes a line" do
      expect( described_class.get_short_id('offre_C00109_10.xml') ).to eq('C00109')
    end

    it "gets nil if the frame does not describe a line" do
      expect( described_class.get_short_id('commun.xml') ).to be_nil
    end
  end
end
