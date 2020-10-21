RSpec.describe Export::NetexGeneric do

  describe "#content_type" do

    subject { export.content_type }

    context "when a profile is selected" do
      let(:export) { Export::NetexGeneric.new profile: 'european' }
      it { is_expected.to eq('application/zip') }
    end

    context "when no profile is selected" do
      let(:export) { Export::NetexGeneric.new profile: 'none' }
      it { is_expected.to eq('text/xml') }
    end

  end

  describe "#file_extension" do

    subject { export.file_extension }

    context "when a profile is selected" do
      let(:export) { Export::NetexGeneric.new profile: 'european' }
      it { is_expected.to eq('zip') }
    end

    context "when no profile is selected" do
      let(:export) { Export::NetexGeneric.new profile: 'none' }
      it { is_expected.to eq('xml') }
    end

  end

  describe "#netex_profile" do

    subject { export.netex_profile }

    context "when a profile is selected" do
      let(:export) { Export::NetexGeneric.new profile: 'european' }
      it { is_expected.to be_instance_of(Netex::Profile::European) }
    end

    context "when no profile is selected" do
      let(:export) { Export::NetexGeneric.new profile: 'none' }
      it { is_expected.to be_nil }
    end

  end

  describe "Routes export" do

    let(:target) { MockNetexTarget.new }
    let(:export_scope) { Export::Scope::All.new context.referential }
    let(:export) { Export::NetexGeneric.new export_scope: export_scope, target: target }

    let(:part) do
      Export::NetexGeneric::Routes.new export
    end

    let(:context) do
      Chouette.create do
        3.times { route }
      end
    end

    let(:routes) { context.routes }
    before { context.referential.switch }

    it "create a Netex::Route for each Chouette Route" do
      part.export!
      expect(target.resources).to have_attributes(count: routes.count)
    end

    xit "create Netex::Routes with line_id tag" do
      part.export!
      expect(target.resources).to all(have_tag(:line_id))
    end

  end

  class MockNetexTarget

    def add(resource)
      resources << resource
    end
    alias << add

    def resources
      @resources ||= []
    end

  end

end
