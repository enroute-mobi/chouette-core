RSpec.describe Shape do

  it { is_expected.to validate_presence_of(:geometry) }
  it { should have_many(:waypoints).order(:position).dependent(:delete_all) }

  describe "#uuid" do

    let(:context) do
      Chouette.create { shape }
    end
    subject { context.shape.reload.uuid }

    UUID_REGEXP = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/

    it "is an UUID (...)" do
      is_expected.to match(UUID_REGEXP)
    end

  end

  describe "#shape_referential" do

    let(:shape_provider) { ShapeProvider.new shape_referential: ShapeReferential.new }
    let(:shape) { Shape.new shape_provider: shape_provider }

    it "uses ShapeProvider by default" do
      expect { shape.validate }.to change(shape, :shape_referential).
                                     from(nil).to(shape_provider.shape_referential)
    end

  end

end
