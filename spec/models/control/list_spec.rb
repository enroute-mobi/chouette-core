# frozen_string_literal: true

RSpec.describe Control::List do
  let(:context) do
    Chouette.create do
      control_list :control_list
    end
  end

  subject(:control_list) { context.control_list(:control_list) }

  describe ".table_name" do
    subject { described_class.table_name }
    it { is_expected.to eq("public.control_lists") }
  end

  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to belong_to(:workbench).required(true) }

  describe '#controls' do
    before do
      3.times do |n|
        control = Control::Dummy.new(name: "Test #{n}")
        control_list.controls << control
      end
    end

    subject { control_list.controls }

    it "store an ordered list" do
      ordered_instances = [
        an_object_having_attributes(position: 1),
        an_object_having_attributes(position: 2),
        an_object_having_attributes(position: 3)
      ]
      is_expected.to match_array(ordered_instances)
    end

    it "store Control instances (not base model)" do
      is_expected.to all(be_an_instance_of(Control::Dummy))
    end

    it "delete controls with list" do
      expect { control_list.destroy }.to change { Control::Base.count }.by(-3)
    end
  end

  describe '#used?' do
    subject { control_list.used? }

    it { is_expected.to eq(false) }

    context 'with processing rules' do
      let(:context) do
        Chouette.create do
          workbench do
            referential :target
            control_list :control_list
            processing_rule control_list: :control_list
          end
        end
      end

      it { is_expected.to eq(true) }
    end
  end
end
