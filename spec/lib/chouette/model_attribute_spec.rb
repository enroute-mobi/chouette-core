# frozen_string_literal: true

RSpec.describe Chouette::ModelAttribute do
  subject { Chouette::ModelAttribute.new(Chouette::Line, attribute) }
  let(:attribute) { :name }

  describe "#model_name" do
    it { expect(subject.model_name).to eq('Line') }
  end

  describe "#resource_name" do
    it { expect(subject.resource_name).to eq('line') }
  end

  describe "#code" do
    it { expect(subject.code).to eq('line#name') }
  end

  describe "#table_name" do
    it { expect(subject.table_name).to eq('public.lines') }
  end

  context '.collection' do
    it 'an empty collection is empty' do
      expect(described_class.collection.to_a).to be_empty
    end

    it 'selects a defined attribute' do
      collection = described_class.collection do
        select Chouette::Line, :name
      end.to_a
      expect(collection.length).to eq(1)
      expect(collection[0].model_class).to eq(Chouette::Line)
      expect(collection[0].name).to eq(:name)
    end

    it 'cannot select an undefined attribute' do
      expect(Rails.logger).to receive(:error).with(
        "Selected Model attribute with class User and name email doesn't exist in the list"
      )
      described_class.collection do
        select User, :email
      end
    end
  end
end
