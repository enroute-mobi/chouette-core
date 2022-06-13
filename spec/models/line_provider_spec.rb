RSpec.describe LineProvider do

  describe "#code_support" do
    let(:context) do
      Chouette.create do
        workbench
        code_space
      end
    end

    let(:workgroup) { context.workgroup }
    let(:line_referential) { workgroup.line_referential }
    let(:code_space) { context.code_space }
    let(:workbench) { context.workbench }
    let(:code_value) { 'code value 1' }

    before do
      LineProvider.create(
        short_name: "Line_provider_1",
        workbench: workbench,
        line_referential: line_referential,
        codes_attributes: [
          code_space: code_space,
          value: code_value
        ]
      )
      workbench.reload
    end

    let(:line_provider) { workbench.line_providers.by_code(code_space, code_value).first }

    let(:expected_code) do
      an_object_having_attributes({
        code_space: code_space,
        value: "code value 1"
      })
    end

    it "should create a line provider and find by code" do
      expect(line_provider).not_to be_nil
    end

    it "should create and associate code codes" do
      expect(line_provider.codes).to include(expected_code)
    end
  end
end
