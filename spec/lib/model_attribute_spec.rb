RSpec.describe ModelAttribute do
  before(:each) do
    ModelAttribute.instance_variable_set(:@__all__, [])
  end

  describe ".define" do
    it "adds a new instance of ModelAttribute to .all" do
      expect do
        ModelAttribute.define(klass: Chouette::Route, name: :name, data_type: :string)
      end.to change { ModelAttribute.all.length }.by(1)

      model_attr = ModelAttribute.all.last

      expect(model_attr).to be_an_instance_of(ModelAttribute)
      expect(model_attr.klass).to eq(Chouette::Route)
      expect(model_attr.name).to eq(:name)
      expect(model_attr.data_type).to eq(:string)
      expect(model_attr.resource_name).to eq(:route)
      expect(model_attr.collection_name).to eq(:routes)
      expect(model_attr.code).to eq('route#name')
    end
  end

  describe ".group_by_class" do
    it "returns all ModelAttributes grouped by klass" do
      ModelAttribute.define(klass: Chouette::Route, name: :name, data_type: :string)
      ModelAttribute.define(klass: Chouette::Route, name: :published_name, data_type: :string)
      ModelAttribute.define(klass: Chouette::JourneyPattern, name: :name, data_type: :string)
      ModelAttribute.define(klass: Chouette::VehicleJourney, name: :number, data_type: :integer)

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

  describe '.find_by_code' do
    it 'returns the model attribute by code' do
      ModelAttribute.define(klass: Chouette::Route, name: :name, data_type: :string)
      
      expect(ModelAttribute.find_by_code('route#name')).to eq(ModelAttribute.new(Chouette::Route, :name, :string))
      expect(ModelAttribute.find_by_code('route#published_name')).to be_nil
    end
  end

  describe "#==" do
    it "returns true when :class_name, :name, :data_type and :options attributes match" do
      route_name = ModelAttribute.new(Chouette::Route, :name, :string, true )
      other_route_name = ModelAttribute.new(Chouette::Route, :name, :string, true )

      expect(route_name == other_route_name).to be true
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
