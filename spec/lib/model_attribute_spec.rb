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

  describe 'names' do
    it 'should all be valid ones' do
      ModelAttribute.all.each do |m|
        expect(m.class_name.method_defined?(m.name)).to be_truthy
      end
    end
  end
end
