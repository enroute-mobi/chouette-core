RSpec.describe FullTimeZoneInput do
  describe ".default_collection" do
    subject { FullTimeZoneInput.default_collection }

    it { is_expected.to include(["(+01:00) Paris", "Europe/Paris"]) }
    it { is_expected.to include(["(-05:00) Montreal", "America/Montreal"]) }

    context "when locale is :fr" do
      around { |example| I18n.with_locale(:fr) { example.run } }

      it { is_expected.to include(["Aucun", nil]) }
    end

    context "when locale is :en" do
      around { |example| I18n.with_locale(:en) { example.run } }

      it { is_expected.to include(["None", nil]) }
    end
  end
end
