# frozen_string_literal: true

RSpec.describe Export::Setup::Scope::PeriodSelector::Duration do
  it { is_expected.to validate_numericality_of(:day_count).only_integer.is_greater_than_or_equal_to(1) }
end

RSpec.describe Export::Setup::Scope::PeriodSelector::Static do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:from) }
    it { is_expected.to validate_presence_of(:to) }

    describe 'from/to range' do
      before { subject.from = Date.current }

      it { is_expected.to allow_value(Date.tomorrow).for(:to) }
      it { is_expected.not_to allow_value(Date.current).for(:to) }
      it { is_expected.not_to allow_value(Date.yesterday).for(:to) }

      context 'when from is nil' do
        before { subject.from = nil }
        it { is_expected.to allow_value(Date.current).for(:to) }
      end

      context 'when to is nil' do
        before { subject.to = nil }
        it { is_expected.to allow_value(Date.current).for(:from) }
      end
    end
  end
end

RSpec.describe Export::Setup::Scope::VehicleJourneys do
  describe 'validations' do
    it { is_expected.not_to allow_value(nil).for(:period) }
    it { is_expected.not_to allow_value(nil).for(:included_lines) }
    it { is_expected.to allow_value(nil).for(:excluded_lines) }
  end
end

RSpec.describe Export::Setup::Base do
  describe 'validations' do
    describe '#code_space_id' do
      let(:code_space_ids) { [1, 2, 3] }
      let(:code_spaces) do
        double(:code_spaces).tap do |code_spaces|
          allow(code_spaces).to receive(:pluck).and_return(code_space_ids)
        end
      end
      let(:parent) { double(:export, workgroup: double(:workgroup, code_spaces: code_spaces)) }

      before { subject.parent = parent }

      it { is_expected.to allow_value(nil).for(:code_space_id) }
      it { is_expected.to allow_value('').for(:code_space_id) }
      it { is_expected.to allow_value(2).for(:code_space_id) }
      it { is_expected.to allow_value('2').for(:code_space_id) }
      it { is_expected.not_to allow_value(4).for(:code_space_id) }
    end
  end
end

RSpec.describe Export::Setup::Gtfs do
  describe 'validations' do
    describe '#scope_setup' do
      context 'when parent is an export' do
        before { subject.parent = Export::Base.new }

        it { is_expected.to allow_value(Export::Setup::Scope::Referential.new).for(:scope_setup) }
        it { is_expected.not_to allow_value(Export::Setup::Scope::PublishedReferential.new).for(:scope_setup) }
        it { is_expected.not_to allow_value(Export::Setup::Scope::Workbench.new).for(:scope_setup) }
        it { is_expected.not_to allow_value(Export::Setup::Scope::Workgroup.new).for(:scope_setup) }
      end

      context 'when parent is a publication setup' do
        before { subject.parent = PublicationSetup.new }

        it { is_expected.not_to allow_value(Export::Setup::Scope::Referential.new).for(:scope_setup) }
        it { is_expected.to allow_value(Export::Setup::Scope::PublishedReferential.new).for(:scope_setup) }
        it { is_expected.not_to allow_value(Export::Setup::Scope::Workbench.new).for(:scope_setup) }
        it { is_expected.not_to allow_value(Export::Setup::Scope::Workgroup.new).for(:scope_setup) }
      end
    end
  end
end

RSpec.describe Export::Setup::Netex do
  describe 'validations' do
    describe '#scope_setup' do
      context 'when parent is an export' do
        before { subject.parent = Export::Base.new }

        it { is_expected.to allow_value(Export::Setup::Scope::Referential.new).for(:scope_setup) }
        it { is_expected.not_to allow_value(Export::Setup::Scope::PublishedReferential.new).for(:scope_setup) }
        it { is_expected.not_to allow_value(Export::Setup::Scope::Workbench.new).for(:scope_setup) }
        it { is_expected.not_to allow_value(Export::Setup::Scope::Workgroup.new).for(:scope_setup) }
      end

      context 'when parent is a publication setup' do
        before { subject.parent = PublicationSetup.new }

        it { is_expected.not_to allow_value(Export::Setup::Scope::Referential.new).for(:scope_setup) }
        it { is_expected.to allow_value(Export::Setup::Scope::PublishedReferential.new).for(:scope_setup) }
        it { is_expected.not_to allow_value(Export::Setup::Scope::Workbench.new).for(:scope_setup) }
        it { is_expected.not_to allow_value(Export::Setup::Scope::Workgroup.new).for(:scope_setup) }
      end
    end

    describe '#profile' do
      it do
        is_expected.to(
          validate_inclusion_of(:profile).in_array(
            %w[none french european idfm/iboo idfm/icar idfm/publication idfm/full]
          )
        )
      end
      it { is_expected.not_to allow_value(nil).for(:profile) }
    end
  end
end

RSpec.describe Export::Setup::Ara do
  describe 'validations' do
    describe '#scope_setup' do
      context 'when parent is an export' do
        before { subject.parent = Export::Base.new }

        it { is_expected.to allow_value(Export::Setup::Scope::Referential.new).for(:scope_setup) }
        it { is_expected.not_to allow_value(Export::Setup::Scope::PublishedReferential.new).for(:scope_setup) }
        it { is_expected.not_to allow_value(Export::Setup::Scope::Workbench.new).for(:scope_setup) }
        it { is_expected.not_to allow_value(Export::Setup::Scope::Workgroup.new).for(:scope_setup) }
      end

      context 'when parent is a publication setup' do
        before { subject.parent = PublicationSetup.new }

        it { is_expected.not_to allow_value(Export::Setup::Scope::Referential.new).for(:scope_setup) }
        it { is_expected.to allow_value(Export::Setup::Scope::PublishedReferential.new).for(:scope_setup) }
        it { is_expected.not_to allow_value(Export::Setup::Scope::Workbench.new).for(:scope_setup) }
        it { is_expected.not_to allow_value(Export::Setup::Scope::Workgroup.new).for(:scope_setup) }
      end
    end
  end
end
