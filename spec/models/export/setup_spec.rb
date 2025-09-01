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

RSpec.describe Export::Setup::Scope::LineSelector::Lines do
  describe 'validations' do
    describe '#line_ids' do
      let(:candidate_line_ids) { [1, 2, 3] }
      let(:candidate_lines) do
        double(:candidate_lines).tap do |candidate_lines|
          allow(candidate_lines).to receive(:pluck).and_return(candidate_line_ids)
        end
      end
      let(:parent) { double(:vehicle_journeys, parent: double(:scope_setup, candidate_lines: candidate_lines)) }

      before { subject.parent = parent }

      it { is_expected.not_to allow_value([]).for(:line_ids) }
      it { is_expected.to allow_value([3, 1]).for(:line_ids) }
      it { is_expected.to allow_value(%w[1 3]).for(:line_ids) }
      it { is_expected.not_to allow_value([2, 4]).for(:line_ids) }
    end
  end
end

RSpec.describe Export::Setup::Scope::LineSelector::Companies do
  describe 'validations' do
    describe '#company_ids' do
      let(:candidate_company_ids) { [1, 2, 3] }
      let(:candidate_companies) do
        double(:candidate_companies).tap do |candidate_companies|
          allow(candidate_companies).to receive(:pluck).and_return(candidate_company_ids)
        end
      end
      let(:parent) { double(:vehicle_journeys, parent: double(:scope_setup, candidate_companies: candidate_companies)) }

      before { subject.parent = parent }

      it { is_expected.not_to allow_value([]).for(:company_ids) }
      it { is_expected.to allow_value([3, 1]).for(:company_ids) }
      it { is_expected.to allow_value(%w[1 3]).for(:company_ids) }
      it { is_expected.not_to allow_value([2, 4]).for(:company_ids) }
    end
  end
end

RSpec.describe Export::Setup::Scope::LineSelector::Networks do
  describe 'validations' do
    describe '#network_ids' do
      let(:candidate_network_ids) { [1, 2, 3] }
      let(:candidate_networks) do
        double(:candidate_networks).tap do |candidate_networks|
          allow(candidate_networks).to receive(:pluck).and_return(candidate_network_ids)
        end
      end
      let(:parent) { double(:vehicle_journeys, parent: double(:scope_setup, candidate_networks: candidate_networks)) }

      before { subject.parent = parent }

      it { is_expected.not_to allow_value([]).for(:network_ids) }
      it { is_expected.to allow_value([3, 1]).for(:network_ids) }
      it { is_expected.to allow_value(%w[1 3]).for(:network_ids) }
      it { is_expected.not_to allow_value([2, 4]).for(:network_ids) }
    end
  end
end

RSpec.describe Export::Setup::Scope::LineSelector::LineProviders do
  describe 'validations' do
    describe '#line_provider_ids' do
      let(:candidate_line_provider_ids) { [1, 2, 3] }
      let(:candidate_line_providers) do
        double(:candidate_line_providers).tap do |candidate_line_providers|
          allow(candidate_line_providers).to receive(:pluck).and_return(candidate_line_provider_ids)
        end
      end
      let(:parent) do
        double(:vehicle_journeys, parent: double(:scope_setup, candidate_line_providers: candidate_line_providers))
      end

      before { subject.parent = parent }

      it { is_expected.not_to allow_value([]).for(:line_provider_ids) }
      it { is_expected.to allow_value([3, 1]).for(:line_provider_ids) }
      it { is_expected.to allow_value(%w[1 3]).for(:line_provider_ids) }
      it { is_expected.not_to allow_value([2, 4]).for(:line_provider_ids) }
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

RSpec.describe Export::Setup::Scope::Referential do
  subject(:setup_scope_referential) { described_class.new }

  describe '#candidate_lines' do
    subject { setup_scope_referential.candidate_lines }

    let(:context) do
      Chouette.create do
        line :line1
        line :line2
        line :out_of_referential_line

        referential lines: %i[line1 line2]
      end
    end
    let(:referential) { context.referential }
    let(:parent) { double(:setup, parent: double(:export, referential: referential)) }

    before { setup_scope_referential.parent = parent }

    it 'only returns lines in referential' do
      is_expected.to match_array(%i[line1 line2].map { |l| context.line(l) })
    end

    context 'when referential is nil' do
      let(:referential) { nil }
      it { is_expected.to be_empty }
    end
  end

  describe '#candidate_companies' do
    subject { setup_scope_referential.candidate_companies }

    let(:context) do
      Chouette.create do
        workgroup :workgroup do
          workbench :workbench do
            company :company1
            company :company2
            company :out_of_referential_company
            line :line1, company: :company1
            line :line2, company: :company2
            line :out_of_referential_line, company: :out_of_referential_company

            referential lines: %i[line1 line2]
          end
          workbench :other_workbench do
            company :other_workbench_company
          end
        end
        workgroup :other_workgroup do
          company :other_company_workgroup
        end
      end
    end
    let(:referential) { context.referential }
    let(:parent) { double(:setup, parent: double(:export, referential: referential)) }

    before { setup_scope_referential.parent = parent }

    it 'only returns companies in referential' do
      is_expected.to(
        match_array(
          %i[company1 company2 out_of_referential_company other_workbench_company].map { |l| context.company(l) }
        )
      )
    end

    context 'when referential is nil' do
      let(:referential) { nil }
      it { is_expected.to be_empty }
    end
  end

  describe '#candidate_networks' do
    subject { setup_scope_referential.candidate_networks }

    let(:context) do
      Chouette.create do
        workgroup :workgroup do
          workbench :workbench do
            network :network1
            network :network2
            network :out_of_referential_network
            line :line1, network: :network1
            line :line2, network: :network2
            line :out_of_referential_line, network: :out_of_referential_network


            referential lines: %i[line1 line2]
          end
          workbench :other_workbench do
            network :other_workbench_network
          end
        end
        workgroup :other_workgroup do
          network :other_workgroup_network
        end
      end
    end
    let(:referential) { context.referential }
    let(:parent) { double(:setup, parent: double(:export, referential: referential)) }

    before { setup_scope_referential.parent = parent }

    it 'only returns networks in referential' do
      is_expected.to(
        match_array(
          %i[network1 network2 out_of_referential_network other_workbench_network].map { |l| context.network(l) }
        )
      )
    end

    context 'when referential is nil' do
      let(:referential) { nil }
      it { is_expected.to be_empty }
    end
  end

  describe '#candidate_line_providers' do
    subject { setup_scope_referential.candidate_line_providers }

    let(:context) do
      Chouette.create do
        workbench :workbench do
          line_provider :line_provider1
          line_provider :line_provider2
        end
        workbench :other_workbench do
          line_provider :out_of_workbench_line_provider
        end
      end
    end
    let(:default_line_provider) { context.workbench(:workbench).default_line_provider }
    let(:parent) { double(:setup, parent: double(:export, workbench: context.workbench(:workbench))) }

    before { setup_scope_referential.parent = parent }

    it 'only returns line providers in workbench' do
      is_expected.to(
        match_array(%i[line_provider1 line_provider2].map { |l| context.line_provider(l) } + [default_line_provider])
      )
    end
  end
end

RSpec.describe Export::Setup::Scope::PublishedReferential do
  subject(:setup_scope_published_referential) { described_class.new }

  describe '#candidate_lines' do
    subject { setup_scope_published_referential.candidate_lines }

    let(:context) do
      Chouette.create do
        workgroup :workgroup do
          line :line1
          line :line2
        end
        workgroup :other_workgroup do
          line :out_of_workgroup_line
        end
      end
    end
    let(:parent) { double(:setup, parent: double(:export, workgroup: context.workgroup(:workgroup))) }

    before { setup_scope_published_referential.parent = parent }

    it 'only returns lines in workgroup' do
      is_expected.to match_array(%i[line1 line2].map { |l| context.line(l) })
    end
  end

  describe '#candidate_companies' do
    subject { setup_scope_published_referential.candidate_companies }

    let(:context) do
      Chouette.create do
        workgroup :workgroup do
          company :company1
          company :company2
        end
        workgroup :other_workgroup do
          company :out_of_workgroup_company
        end
      end
    end
    let(:parent) { double(:setup, parent: double(:export, workgroup: context.workgroup(:workgroup))) }

    before { setup_scope_published_referential.parent = parent }

    it 'only returns companies in workgroup' do
      is_expected.to match_array(%i[company1 company2].map { |l| context.company(l) })
    end
  end

  describe '#candidate_networks' do
    subject { setup_scope_published_referential.candidate_networks }

    let(:context) do
      Chouette.create do
        workgroup :workgroup do
          network :network1
          network :network2
        end
        workgroup :other_workgroup do
          network :out_of_workgroup_network
        end
      end
    end
    let(:parent) { double(:setup, parent: double(:export, workgroup: context.workgroup(:workgroup))) }

    before { setup_scope_published_referential.parent = parent }

    it 'only returns networks in workgroup' do
      is_expected.to match_array(%i[network1 network2].map { |l| context.network(l) })
    end
  end

  describe '#candidate_line_providers' do
    subject { setup_scope_published_referential.candidate_line_providers }

    let(:context) do
      Chouette.create do
        workgroup :workgroup do
          workbench :workbench do
            line_provider :line_provider1
            line_provider :line_provider2
          end
        end
        workgroup :other_workgroup do
          line_provider :out_of_workgroup_line_provider
        end
      end
    end
    let(:default_line_provider) { context.workbench(:workbench).default_line_provider }
    let(:parent) { double(:setup, parent: double(:export, workgroup: context.workgroup(:workgroup))) }

    before { setup_scope_published_referential.parent = parent }

    it 'only returns line providers in workgroup' do
      is_expected.to(
        match_array(%i[line_provider1 line_provider2].map { |l| context.line_provider(l) } + [default_line_provider])
      )
    end
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
