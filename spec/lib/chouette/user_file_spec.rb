RSpec.describe Chouette::UserFile do

  context "#name" do

    it "concats basename and extension" do
      expect(Chouette::UserFile.new(basename: "basename", extension: "ext").name).to eq("basename.ext")
    end

  end

end
