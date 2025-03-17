# frozen_string_literal: true

RSpec.describe Export::Gtfs::Scope do
  subject(:scope) { described_class.new(initial_scope, export: export) }
  let(:export) { Export::Gtfs.new }
  let(:initial_scope) { double }

  describe 'StopAreas concerning' do
    describe '#ignore_parent_stop_places?' do
      subject { scope.ignore_parent_stop_places? }

      context 'when Export#ignore_parent_stop_places is true' do
        before { export.ignore_parent_stop_places = true }

        it { is_expected.to be_truthy }
      end

      context 'when Export#ignore_parent_stop_places is false' do
        before { export.ignore_parent_stop_places = false }

        it { is_expected.to be_falsy }
      end
    end

    describe '#prefer_referent_stop_areas?' do
      subject { scope.prefer_referent_stop_areas? }

      context 'when Export#prefer_referent_stop_areas is true' do
        before { export.prefer_referent_stop_area = true }

        it { is_expected.to be_truthy }
      end

      context 'when Export#prefer_referent_stop_areas is false' do
        before { export.prefer_referent_stop_area = false }

        it { is_expected.to be_falsy }
      end
    end

    describe '#scoped_stop_areas' do
      subject { scope.scoped_stop_areas }

      let(:context) do
        Chouette.create do
          stop_area :parent, name: 'Parent', area_type: Chouette::AreaType::STOP_PLACE
          stop_area :child, name: 'Child', parent: :parent
        end
      end

      let(:child) { context.stop_area :child }
      let(:parent) { context.stop_area :parent }

      let(:initial_scope) { double stop_areas: Chouette::StopArea.where(id: child) }

      context 'when ignore_parent_stop_places? is enabled' do
        before { allow(scope).to receive(:ignore_parent_stop_places?).and_return(true) }

        it { is_expected.to include(child) }
        it { is_expected.to_not include(parent) }
      end

      context 'when ignore_parent_stop_places? is disabled' do
        before { allow(scope).to receive(:ignore_parent_stop_places?).and_return(false) }

        it { is_expected.to include(child) }
        it { is_expected.to include(parent) }
      end
    end

    describe '#stop_areas' do
      subject { scope.stop_areas }

      let(:context) do
        Chouette.create do
          stop_area :referent, name: 'Referent', is_referent: true
          stop_area :particular, name: 'Particular', referent: :referent

          stop_area :other, name: 'Other'
        end
      end

      let(:particular) { context.stop_area :particular }
      let(:referent) { context.stop_area :referent }
      let(:other) { context.stop_area :other }

      before { allow(scope).to receive(:scoped_stop_areas) { Chouette::StopArea.where(id: [particular, other]) } }

      context 'when prefer_referent_stop_areas? is enabled' do
        before { allow(scope).to receive(:prefer_referent_stop_areas?).and_return(true) }

        it { is_expected.to include(referent) }
        it { is_expected.to_not include(particular) }

        it { is_expected.to include(other) }
      end

      context 'when prefer_referent_stop_areas? is disabled' do
        before { allow(scope).to receive(:prefer_referent_stop_areas?).and_return(false) }

        it { is_expected.to_not include(referent) }
        it { is_expected.to include(particular) }

        it { is_expected.to include(other) }
      end
    end

    describe '#referenced_stop_areas' do
      subject { scope.referenced_stop_areas }

      context 'when prefer_referent_stop_area? is disabled' do
        before { allow(scope).to receive(:prefer_referent_stop_areas?).and_return(false) }

        let(:context) do
          Chouette.create do
            stop_area
          end
        end

        let(:initial_scope) { double stop_areas: Chouette::StopArea.where(id: context.stop_area) }

        it { is_expected.to be_empty }
      end

      context 'when prefer_referent_stop_area? is enabled' do
        before { allow(scope).to receive(:prefer_referent_stop_areas?).and_return(true) }

        let(:context) do
          Chouette.create do
            stop_area :referent, name: 'Referent', is_referent: true
            stop_area :particular, name: 'Particular', referent: :referent

            stop_area :other
          end
        end

        let(:particular) { context.stop_area :particular }
        let(:referent) { context.stop_area :referent }
        let(:other) { context.stop_area :other }

        before { allow(scope).to receive(:scoped_stop_areas) { Chouette::StopArea.where(id: [particular, other]) } }

        it { is_expected.to include(particular) }
        it { is_expected.to_not include(other) }
      end
    end

    describe '#dependencies_stop_areas' do
      subject { scope.dependencies_stop_areas }

      context 'when prefer_referent_stop_area? is disabled' do
        before { allow(scope).to receive(:prefer_referent_stop_areas?).and_return(false) }

        let(:context) do
          Chouette.create do
            stop_area :referent, name: 'Referent', is_referent: true
            stop_area :particular, name: 'Particular', referent: :referent
          end
        end

        let(:particular) { context.stop_area :particular }
        let(:initial_scope) { double stop_areas: Chouette::StopArea.where(id: particular) }

        it { is_expected.to include(particular) }
      end

      context 'when prefer_referent_stop_area? is enabled' do
        before { allow(scope).to receive(:prefer_referent_stop_areas?).and_return(true) }

        let(:context) do
          Chouette.create do
            stop_area :referent, name: 'Referent', is_referent: true
            stop_area :particular, name: 'Particular', referent: :referent

            stop_area :other
          end
        end

        let(:particular) { context.stop_area :particular }
        let(:referent) { context.stop_area :referent }
        let(:other) { context.stop_area :other }

        before { allow(scope).to receive(:scoped_stop_areas) { Chouette::StopArea.where(id: [particular, other]) } }

        it { is_expected.to include(particular) }
        it { is_expected.to include(referent) }
        it { is_expected.to include(other) }
      end
    end

    describe '#entrances' do
      subject { scope.entrances }

      let(:context) do
        Chouette.create do
          stop_area :first

          entrance :scoped, stop_area: :first
          entrance
        end
      end

      let(:stop_area) { context.stop_area :first }
      let(:entrance) { context.entrance :scoped }

      before do
        allow(scope).to receive(:stop_area_referential) { context.stop_area_referential }

        allow(scope).to receive(:dependencies_stop_areas) do
          Chouette::StopArea.where(id: [stop_area])
        end
      end

      it { is_expected.to include(entrance) }
    end

    describe '#connection_links' do
      subject { scope.connection_links }

      let(:context) do
        Chouette.create do
          stop_area :first
          stop_area :other
          stop_area :other2

          connection_link departure: :first, arrival: :other
          connection_link arrival: :first, departure: :other
          connection_link :unscoped, departure: :other, arrival: :other2
        end
      end

      let(:stop_area) { context.stop_area :first }
      let(:unscoped) { context.connection_link :unscoped }

      before do
        allow(scope).to receive(:stop_area_referential) { context.stop_area_referential }

        allow(scope).to receive(:dependencies_stop_areas) do
          Chouette::StopArea.where(id: [stop_area])
        end
      end

      it { is_expected.to_not include(unscoped) }
    end
  end

  describe 'Lines concerning' do
    describe '#prefer_referent_lines?' do
      subject { scope.prefer_referent_lines? }

      context 'when Export#prefer_referent_lines is true' do
        before { export.prefer_referent_line = true }

        it { is_expected.to be_truthy }
      end

      context 'when Export#prefer_referent_lines is false' do
        before { export.prefer_referent_line = false }

        it { is_expected.to be_falsy }
      end
    end

    describe '#scoped_lines' do
      subject { scope.scoped_lines }

      let(:initial_scope) { double(lines: double('Initial Scope lines')) }

      it { is_expected.to eq(initial_scope.lines) }
    end

    describe '#referenced_lines' do
      subject { scope.referenced_lines }

      context 'when prefer_referent_lines? is disabled' do
        before { allow(scope).to receive(:prefer_referent_lines?).and_return(false) }

        let(:context) do
          Chouette.create do
            line
          end
        end

        let(:initial_scope) { double lines: Chouette::Line.where(id: context.line) }

        it { is_expected.to be_empty }
      end

      context 'when prefer_referent_lines? is enabled' do
        before { allow(scope).to receive(:prefer_referent_lines?).and_return(true) }

        let(:context) do
          Chouette.create do
            line :referent, name: 'Referent', is_referent: true
            line :particular, name: 'Particular', referent: :referent

            line :other
          end
        end

        let(:particular) { context.line :particular }
        let(:referent) { context.line :referent }
        let(:other) { context.line :other }

        before { allow(scope).to receive(:scoped_lines) { Chouette::Line.where(id: [particular, other]) } }

        it { is_expected.to include(particular) }
        it { is_expected.to_not include(other) }
      end
    end

    describe '#lines' do
      subject { scope.lines }

      let(:context) do
        Chouette.create do
          line :referent, name: 'Referent', is_referent: true
          line :particular, name: 'Particular', referent: :referent

          line :other, name: 'Other'
        end
      end

      let(:particular) { context.line :particular }
      let(:referent) { context.line :referent }
      let(:other) { context.line :other }

      before { allow(scope).to receive(:scoped_lines) { Chouette::Line.where(id: [particular, other]) } }

      context 'when prefer_referent_lines? is enabled' do
        before { allow(scope).to receive(:prefer_referent_lines?).and_return(true) }

        it { is_expected.to include(referent) }
        it { is_expected.to_not include(particular) }

        it { is_expected.to include(other) }
      end

      context 'when prefer_referent_lines? is disabled' do
        before { allow(scope).to receive(:prefer_referent_lines?).and_return(false) }

        it { is_expected.to_not include(referent) }
        it { is_expected.to include(particular) }

        it { is_expected.to include(other) }
      end
    end
  end

  describe 'Companies concerning' do
    describe '#prefer_referent_companies?' do
      subject { scope.prefer_referent_companies? }

      context 'when Export#prefer_referent_companies is true' do
        before { export.prefer_referent_company = true }

        it { is_expected.to be_truthy }
      end

      context 'when Export#prefer_referent_companies is false' do
        before { export.prefer_referent_company = false }

        it { is_expected.to be_falsy }
      end
    end

    describe '#referenced_companies' do
      subject { scope.referenced_companies }

      context 'when prefer_referent_companies? is disabled' do
        before { allow(scope).to receive(:prefer_referent_companies?).and_return(false) }

        let(:context) do
          Chouette.create do
            company
          end
        end

        let(:initial_scope) { double companies: Chouette::Company.where(id: context.company) }

        it { is_expected.to be_empty }
      end

      context 'when prefer_referent_companies? is enabled' do
        before { allow(scope).to receive(:prefer_referent_companies?).and_return(true) }

        let(:context) do
          Chouette.create do
            company :referent, name: 'Referent', is_referent: true
            company :particular, name: 'Particular', referent: :referent

            company :other
          end
        end

        let(:particular) { context.company :particular }
        let(:referent) { context.company :referent }
        let(:other) { context.company :other }

        before { allow(scope).to receive(:scoped_companies) { Chouette::Company.where(id: [particular, other]) } }

        it { is_expected.to include(particular) }
        it { is_expected.to_not include(other) }
      end
    end

    describe '#scoped_companies' do
      subject { scope.scoped_companies }

      let(:context) do
        Chouette.create do
          company :first
          company :wrong

          line company: :first
          line company: :first

          line :unscoped, company: :wrong
        end
      end

      before do
        allow(scope).to receive(:dependencies_lines).and_return(scoped_lines)
        allow(scope).to receive(:line_referential) { context.line_referential }
      end

      let(:scoped_lines) { context.line_referential.lines.where.not(id: unscoped_line) }
      let(:unscoped_line) { context.line :unscoped }

      let(:scoped_company) { context.company :first }

      it 'contains Companies associated to scoped lines' do
        is_expected.to match_array(scoped_company)
      end
    end

    describe '#companies' do
      subject { scope.companies }

      let(:context) do
        Chouette.create do
          company :referent, name: 'Referent', is_referent: true
          company :particular, name: 'Particular', referent: :referent

          company :other, name: 'Other'
        end
      end

      let(:particular) { context.company :particular }
      let(:referent) { context.company :referent }
      let(:other) { context.company :other }

      before { allow(scope).to receive(:scoped_companies) { Chouette::Company.where(id: [particular, other]) } }

      context 'when prefer_referent_companies? is enabled' do
        before { allow(scope).to receive(:prefer_referent_companies?).and_return(true) }

        it { is_expected.to include(referent) }
        it { is_expected.to_not include(particular) }

        it { is_expected.to include(other) }
      end

      context 'when prefer_referent_companies? is disabled' do
        before { allow(scope).to receive(:prefer_referent_companies?).and_return(false) }

        it { is_expected.to_not include(referent) }
        it { is_expected.to include(particular) }

        it { is_expected.to include(other) }
      end
    end
  end
end
