RSpec.describe Code do

  let(:context) do
    Chouette.create do
      workgroup do
        stop_area
      end
    end
  end

  let(:workgroup) { context.workgroup }
  let(:code_space) { workgroup.code_spaces.create short_name: 'test' }
  let(:resource) { context.stop_area }

  describe "validation" do

    def code(attributes = {})
      attributes.reverse_merge! value: 'dummy', resource: resource, code_space: code_space
      Code.new attributes
    end

    it "validates value presence" do
      expect(code(value: nil)).to_not be_valid
      expect(code(value: 'dummy')).to be_valid
    end

    it "validates resource presence" do
      expect(code(resource: nil)).to_not be_valid
      expect(code(resource: resource)).to be_valid
    end

    it "validates code_space presence" do
      expect(code(code_space: nil)).to_not be_valid
      expect(code(code_space: code_space)).to be_valid
    end

  end

end
