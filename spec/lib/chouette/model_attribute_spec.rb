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


  context 'when attribute is not a relation' do
    let(:attribute) { :name }
    describe "#table_name" do
      it { expect(subject.table_name).to be_nil }
    end

  end

  context 'when attribute is a relation' do
    let(:attribute) { :company}

    describe "#table_name" do
      it { expect(subject.table_name).to eq('public.companies') }
    end
  end
end
