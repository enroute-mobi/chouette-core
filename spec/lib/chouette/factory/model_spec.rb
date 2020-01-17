require "rails_helper"

RSpec.describe Chouette::Factory::Model do

  describe "#define" do

    subject(:model) { Chouette::Factory::Model.new(:root) }

    describe "attribute method" do
      it "add defined attribute" do
        model.define { attribute :test }
        expect(model.attributes.values.map(&:name)).to eq([:test])
      end

      it "save attribute value" do
        model.define { attribute :test, 42 }
        expect(model.attributes[:test].value).to eq(42)
      end

      it "support Proc as value" do
        model.define { attribute(:test) { 42 } }
        expect(model.attributes[:test].value.call).to eq(42)
      end
    end

    describe "model method" do
      it "add defined model" do
        model.define { model(:test) }
        expect(model.models.values.map(&:name)).to eq([:test])
      end

      it "save given model options" do
        model.define { model(:test, required: true) }
        expect(model.models[:test].required).to be_truthy
      end

      it "use model definition" do
        model.define { model(:test) { attribute(:first) } }
        expect(model.models[:test].attributes.values.map(&:name)).to eq([:first])
      end
    end
  end

end
