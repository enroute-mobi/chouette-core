# frozen_string_literal: true

RSpec.describe Macro::List do
  let(:context) do
    Chouette.create do
      macro_list :macro_list
    end
  end

  subject(:macro_list) { context.macro_list(:macro_list) }

  describe ".table_name" do
    subject { described_class.table_name }
    it { is_expected.to eq("public.macro_lists") }
  end

  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to belong_to(:workbench).required(true) }
  
  describe '#macros' do
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

  describe '#used?' do
    subject { macro_list.used? }

    it { is_expected.to eq(false) }

    context 'with processing rules' do
      let(:context) do
        Chouette.create do
          workbench do
            referential :target
            macro_list :macro_list
            processing_rule macro_list: :macro_list
          end
        end
      end

      it { is_expected.to eq(true) }
    end
  end
end
