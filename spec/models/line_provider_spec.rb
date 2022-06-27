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
        name: "Line Provider 1",
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

  describe "#used?" do
    subject { line_provider.used? }

    context "when a Line is associated" do
      let(:context) { Chouette.create { line } }
      let(:line_provider) { context.line.line_provider }

      it { is_expected.to be_truthy }
    end

    context "when a Company is associated" do
      let(:context) { Chouette.create { company } }
      let(:line_provider) { context.company.line_provider }

      it { is_expected.to be_truthy }
    end

    context "when a Network is associated" do
      let(:context) { Chouette.create { network } }
      let(:line_provider) { context.network.line_provider }

      it { is_expected.to be_truthy }
    end
    context "when a Line Notice is associated" do
      let(:context) { Chouette.create { line_notice } }
      let(:line_provider) { context.line_notice.line_provider }

      it { is_expected.to be_truthy }
    end
    context "when a Line Routing Constraint is associated", pending: true do
      let(:context) { Chouette.create { line_routing_constraint } }
      let(:line_provider) { context.line_routing_constraint.line_provider }

      it { is_expected.to be_truthy }
    end

    context "when no resource is associated" do
      let(:context) { Chouette.create { line_provider } }
      let(:line_provider) { context.line_provider }

      it { is_expected.to be_falsy }
    end
  end
end
