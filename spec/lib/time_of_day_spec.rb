RSpec.describe TimeOfDay do

  describe ".parse" do

    [
      ["17", TimeOfDay.new(17)],
      ["17:41", TimeOfDay.new(17, 41)],
      ["17:41:12", TimeOfDay.new(17, 41, 12)],
      ["17:41:00", TimeOfDay.new(17, 41)],
      ["08:05:02", TimeOfDay.new(8, 5,2)],
      ["17:00:00", TimeOfDay.new(17)],
      ["00:00:00", TimeOfDay.new(0)],
      ["23:59:59", TimeOfDay.new(23,59,59)],
    ].each do |definition, expected|
      it "creates #{expected.inspect} from '#{definition}'" do
        expect(TimeOfDay.parse(definition)).to eq(expected)
      end
    end


  end

end
