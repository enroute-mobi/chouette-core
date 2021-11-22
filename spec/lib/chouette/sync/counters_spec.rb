RSpec.describe Chouette::Sync::Counters do

  def counters(values = {})
    Chouette::Sync::Counters.new values
  end

  def for_each_type
    Chouette::Sync::Counters.types.each do |type|
      yield type
    end
  end

  describe "#create_count" do

    it "returns value of :create counter" do
      expect(counters(create: 1).create).to eq(1)
    end

  end

  describe "#sum" do

    it "sums count values" do
      for_each_type do |type|
        expect(counters(type => 1).sum(counters(type => 1)).count(type)).to eq(2)
      end
    end

  end

  describe ".sum" do

    it "sums all given Cunters" do
      sum = Chouette::Sync::Counters.sum([counters(create: 1)] * 3)
      expect(sum.create).to eq(3)
    end

  end

  describe "#increment_count" do

    it "increments by 1 the given type" do
      for_each_type do |type|
        expect { subject.increment_count(type) }.to change { subject.count(type);  }.by(1)
      end
    end

  end

  describe '#total' do
  end

end
