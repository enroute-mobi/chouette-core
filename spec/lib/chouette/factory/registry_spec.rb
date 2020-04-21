RSpec.describe Chouette::Factory::Registry do

  let(:registry) { subject }

  describe "#register" do

    let(:instance) { Chouette::Route.new }
    let(:attributes) { { dummy: true } }

    it "should add an entry with given instance and attributes" do
      registry.register instance, attributes

      expect(registry.entries.size).to eq(1)
      expect(registry.entries.first.instance).to eq(instance)
      expect(registry.entries.first.attributes).to eq(attributes)
    end

  end

  describe "#select" do

    let(:instance) { Chouette::Route.new }

    it "should return an empty array when no entry matchs" do
      expect(registry.select(name: "dummy")).to eq([])

      registry.register instance, name: "test"
      expect(registry.select(name: "dummy")).to eq([])
    end

    it "should select entry by name" do
      registry.register instance, name: "test"
      expect(registry.select(name: "test")).to eq([instance])
    end

    it "should select entry by model name" do
      registry.register instance, model_name: "route"
      expect(registry.select(model_name: "route")).to eq([instance])
    end

    it "should select entry by name and model" do
      registry.register Chouette::Line.new, name: "test"
      registry.register instance, name: "test"
      expect(registry.select(name: "test", model_name: "route")).to eq([instance])
    end

  end

  describe "#find" do

    let(:instance) { Chouette::Route.new }

    it "should return the matching entry" do
      registry.register instance, model_name: "route"
      expect(registry.find(model_name: "route")).to eq(instance)
    end

    it "should return nil when no entry matches" do
      expect(registry.find(name: "dummy")).to eq(nil)
    end

    it "raises a Chouette::Factory::Error when several entries match" do
      registry.register Chouette::Line.new, name: "test"
      registry.register instance, name: "test"

      expect { registry.find(name: "test") }.to raise_error(Chouette::Factory::Error)
    end

  end

  describe "#find!" do

    let(:instance) { Chouette::Route.new }

    it "should return the matching entry" do
      registry.register instance, model_name: "route"
      expect(registry.find!(model_name: "route")).to eq(instance)
    end

    it "raises a Chouette::Factory::Error when no entry matches" do
      expect { registry.find!(name: "dummy") }.to raise_error(Chouette::Factory::Error)
    end

  end

  describe "dynamic_model_method" do

    let(:instance) { Chouette::Route.new }

    describe "singular usage" do

      it "should find a single instance with method name as model name" do
        registry.register instance, model_name: "route"
        expect(registry.dynamic_model_method("route")).to eq(instance)
      end

      it "should find a single instance with first argument as name" do
        registry.register Chouette::Route.new, model_name: "route"
        registry.register instance, model_name: "route", name: :test
        expect(registry.dynamic_model_method("route", :test)).to eq(instance)
      end

      it "should return nil when no instance matches" do
        expect(registry.dynamic_model_method("route")).to be_nil
      end

    end

    describe "plural usage" do

      let(:second_instance) { Chouette::Route.new }

      it "should find instances with (singularized) method name as model name" do
        registry.register instance, model_name: "route"
        registry.register second_instance, model_name: "route"
        expect(registry.dynamic_model_method("routes")).to contain_exactly(instance, second_instance)
      end

      it "should with first argument as name" do
        registry.register Chouette::Route.new, model_name: "route"
        registry.register instance, model_name: "route", name: :test
        expect(registry.dynamic_model_method("routes", :test)).to eq([instance])
      end

      it "should return an empty array when no instance matches" do
        expect(registry.dynamic_model_method("routes")).to eq([])
      end

    end

  end

end
