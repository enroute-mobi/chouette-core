RSpec.describe Macro::List do
  let(:context) do
    Chouette.create { workbench }
  end

  subject(:macro_list) do
    context.workbench.macro_lists.create! name: "Test"
  end

  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to belong_to(:workbench).required(true) }

  describe ".macros"do
    before do
      3.times do |n|
        macro = Macro::Dummy.new(name: "Test #{n}")
        macro_list.macros << macro
      end
    end

    subject { macro_list.macros }

    it "store an ordered list" do
      ordered_instances = [
        an_object_having_attributes(position: 1),
        an_object_having_attributes(position: 2),
        an_object_having_attributes(position: 3)
      ]
      is_expected.to match_array(ordered_instances)
    end

    it "store Macro instances (not base model)" do
      is_expected.to all(be_an_instance_of(Macro::Dummy))
    end

    it "delete macros with list" do
      expect { macro_list.destroy }.to change { Macro::Base.count }.by(-3)
    end
  end
end

RSpec.describe Macro::Base do

  subject { Macro::Dummy.new }
  it { is_expected.to belong_to(:macro_list).required(true) }

end
