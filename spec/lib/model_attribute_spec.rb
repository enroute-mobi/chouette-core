RSpec.describe ModelAttribute do
  before(:each) do
    ModelAttribute.instance_variable_set(:@__all__, [])
  end

  describe ".define" do
    it "adds a new instance of ModelAttribute to .all" do
      expect do
        ModelAttribute.define(Chouette::Route, :name, :string)
      end.to change { ModelAttribute.all.length }.by(1)

      model_attr = ModelAttribute.all.last

      expect(model_attr).to be_an_instance_of(ModelAttribute)
      expect(model_attr.klass).to eq(:route)
      expect(model_attr.name).to eq(:name)
      expect(model_attr.data_type).to eq(:string)
    end
  end

  describe ".classes" do
    it "returns the list of classes of ModelAttributes in .all" do
      ModelAttribute.define(Chouette::Route, :name, :string)
      ModelAttribute.define(Chouette::JourneyPattern, :name, :string)

      expect(ModelAttribute.classes).to match_array([
        'Route',
        'JourneyPattern',
      ])
    end
  end

  describe ".from_code" do
    it "returns a ModelAttribute from a given code" do
      ModelAttribute.define(Chouette::JourneyPattern, :name, :string)

      expect(ModelAttribute.from_code('journey_pattern#name')).to eq(
        ModelAttribute.new(Chouette::JourneyPattern, :name, :string)
      )
    end
  end

  describe ".group_by_class" do
    it "returns all ModelAttributes grouped by klass" do
      ModelAttribute.define(Chouette::Route, :name, :string)
      ModelAttribute.define(Chouette::Route, :published_name, :string)
      ModelAttribute.define(Chouette::JourneyPattern, :name, :string)
      ModelAttribute.define(Chouette::VehicleJourney, :number, :integer)

      expect(ModelAttribute.group_by_class).to eq({
        route: [
          ModelAttribute.new(Chouette::Route, :name, :string),
          ModelAttribute.new(Chouette::Route, :published_name, :string),
        ],
        journey_pattern: [
          ModelAttribute.new(Chouette::JourneyPattern, :name, :string),
        ],
        vehicle_journey: [
          ModelAttribute.new(Chouette::VehicleJourney, :number, :integer)
        ]
      })
    end
  end

  describe ".methods_by_class" do
    it "returns all ModelAttributes for a given class" do
      ModelAttribute.define(Chouette::Route, :name, :string)
      ModelAttribute.define(Chouette::Route, :published_name, :string)
      ModelAttribute.define(Chouette::JourneyPattern, :name, :string)

      expect(ModelAttribute.methods_by_class(:route)).to match_array([
        ModelAttribute.new(Chouette::Route, :name, :string),
        ModelAttribute.new(Chouette::Route, :published_name, :string),
      ])
    end
  end

  describe ".methods_by_class_and_type" do
    it "returns ModelAttributes of a certain class and type" do
      ModelAttribute.define(Chouette::Route, :name, :string)
      ModelAttribute.define(Chouette::Route, :checked_at, :date)
      ModelAttribute.define(Chouette::JourneyPattern, :name, :string)

      expect(ModelAttribute.methods_by_class_and_type(:route, :string)).to match_array([
        ModelAttribute.new(Chouette::Route, :name, :string)
      ])
    end
  end

  describe "#code" do
    it "returns a string representation of the attribute" do
      model_attr = ModelAttribute.new(Chouette::Route, :name, :string)

      expect(model_attr.code).to eq('route#name')
    end
  end

  describe "#==" do
    it "returns true when :class_name, :name, :data_type and :options attributes match" do
      route_name = ModelAttribute.new(Chouette::Route, :name, :string, **{ mandatory: true })
      other_route_name = ModelAttribute.new(Chouette::Route, :name, :string,  **{ mandatory: true })

      expect(route_name == other_route_name).to be true
    end
  end
end
