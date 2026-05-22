# frozen_string_literal: true

RSpec.describe Import::Lookup::Default do
  let(:lookup) { Import::Lookup.default(import) }

  def self.with_response(on:, &block)
    context 'with response callback' do
      let(:callback) { double('callback') }
      let(:lookup) { super().on_response(on: on) { |response, *args| callback.callback(response, *args) } }

      instance_eval(&block)
    end
  end

  let(:code_space) { nil }
  let(:workbench) { context.workbench(:workbench) }
  let(:stop_area_provider) { nil }
  let(:line_provider) { nil }
  let(:shape_provider) { nil }
  let(:override_internal_identifiers) { false }
  let(:import) do
    double(
      'import',
      code_space: code_space,
      workbench: workbench,
      stop_area_provider: stop_area_provider,
      line_provider: line_provider,
      shape_provider: shape_provider,
      override_internal_identifiers?: override_internal_identifiers
    )
  end
  let(:arguments) { { arg1: 'v1', arg2: 'v2' } }

  # so that workbench scope is different from workgroup scope
  before { allow(Workgroup).to receive(:workbench_scopes_class).and_return(Stif::WorkbenchScopes) }

  describe '#stop_areas' do
    subject(:stop_areas) { lookup.stop_areas }

    let(:context) do
      Chouette.create do
        organisation :organisation, sso_attributes: { 'stop_area_providers' => 2.times.map(&:to_s) }
        workgroup owner: :organisation do
          workbench organisation: :organisation do
            stop_area registration_number: 'workgroup_code'
            stop_area registration_number: 'unknown_code'
          end
        end
        workgroup :workgroup, owner: :organisation do
          workbench organisation: :organisation do
            stop_area :objectid_workgroup_stop_area, objectid: 'workgroup_code'
            stop_area registration_number: 'provider_code'
            stop_area registration_number: 'workbench_code'
            stop_area :workgroup_stop_area, registration_number: 'workgroup_code'
          end

          workbench :workbench, organisation: :organisation do
            stop_area_provider objectid: 'FR1:OrganisationalUnit:0:' do
              stop_area :objectid_workbench_stop_area, objectid: 'workbench_code'
              stop_area :workbench_stop_area, registration_number: 'workbench_code'
            end
            stop_area_provider :stop_area_provider, objectid: 'FR1:OrganisationalUnit:1:' do
              stop_area :objectid_provider_stop_area, objectid: 'provider_code', registration_number: 'other_code'
              stop_area :provider_stop_area, registration_number: 'provider_code'
            end
          end
        end
      end
    end
    let(:stop_area_provider) { context.stop_area_provider(:stop_area_provider) }

    describe '#find_id' do
      subject { stop_areas.find_id(code, **arguments) }

      context 'when code is blank' do
        let(:code) { '' }

        it { is_expected.to be_nil }
      end

      context 'when code is the registration number of a stop area in provider' do
        let(:code) { 'provider_code' }

        it 'returns the id of the stop area in the provider having this registration number' do
          is_expected.to eq(context.stop_area(:provider_stop_area).id)
        end

        with_response(on: :stop_areas) do
          it 'calls response callback' do
            expect(callback).to receive(:callback).with(
              have_attributes(
                class: Import::Lookup::Response,
                source: :provider,
                code: 'provider_code',
                model_id: context.stop_area(:provider_stop_area).id,
                model: nil
              ),
              arguments
            )
            subject
          end
        end

        context 'with cache' do
          before do
            stop_areas.find_id(code) # cache the response
            Chouette::StopArea.destroy_all
          end

          it 'returns data in the cache' do
            is_expected.to eq(context.stop_area(:provider_stop_area).id)
          end
        end

        context 'when override_internal_identifiers is true' do
          let(:override_internal_identifiers) { true }

          it 'returns the id of the stop area in the provider having this objectid' do
            is_expected.to eq(context.stop_area(:objectid_provider_stop_area).id)
          end
        end

        context 'when there is no stop area provider' do
          let(:stop_area_provider) { nil }

          it 'returns the id of the stop area in the workbench having this registration number' do
            is_expected.to eq(context.stop_area(:provider_stop_area).id)
          end

          with_response(on: :stop_areas) do
            it 'calls response callback' do
              expect(callback).to receive(:callback).with(
                have_attributes(
                  class: Import::Lookup::Response,
                  source: :workbench,
                  code: 'provider_code',
                  model_id: context.stop_area(:provider_stop_area).id,
                  model: nil
                ),
                arguments
              )
              subject
            end
          end
        end
      end

      context 'when code is the registration number of a stop area in workbench' do
        let(:code) { 'workbench_code' }

        it 'returns the id of the stop area in the workbench having this registration number' do
          is_expected.to eq(context.stop_area(:workbench_stop_area).id)
        end

        with_response(on: :stop_areas) do
          it 'calls response callback' do
            expect(callback).to receive(:callback).with(
              have_attributes(
                class: Import::Lookup::Response,
                source: :workbench,
                code: 'workbench_code',
                model_id: context.stop_area(:workbench_stop_area).id,
                model: nil
              ),
              arguments
            )
            subject
          end
        end

        context 'when override_internal_identifiers is true' do
          let(:override_internal_identifiers) { true }

          it 'returns the id of the stop area in the workbench having this objectid' do
            is_expected.to eq(context.stop_area(:objectid_workbench_stop_area).id)
          end
        end
      end

      context 'when code is the registration number of a stop area in workgroup' do
        let(:code) { 'workgroup_code' }

        it 'returns the id of the stop area in the workgroup having this registration number' do
          is_expected.to eq(context.stop_area(:workgroup_stop_area).id)
        end

        with_response(on: :stop_areas) do
          it 'calls response callback' do
            expect(callback).to receive(:callback).with(
              have_attributes(
                class: Import::Lookup::Response,
                source: :workgroup,
                code: 'workgroup_code',
                model_id: context.stop_area(:workgroup_stop_area).id,
                model: nil
              ),
              arguments
            )
            subject
          end
        end

        context 'when override_internal_identifiers is true' do
          let(:override_internal_identifiers) { true }

          it 'returns the id of the stop area in the workgroup having this objectid' do
            is_expected.to eq(context.stop_area(:objectid_workgroup_stop_area).id)
          end
        end
      end

      context 'when code is unknown' do
        let(:code) { 'unknown_code' }

        it { is_expected.to be_nil }

        with_response(on: :stop_areas) do
          it 'calls response callback' do
            expect(callback).to receive(:callback).with(
              have_attributes(
                class: Import::Lookup::Response,
                source: :none,
                code: 'unknown_code',
                model_id: nil,
                model: nil
              ),
              arguments
            )
            subject
          end
        end

        context 'with cache' do
          before do
            stop_areas.find_id(code) # cache the response
            context.stop_area_provider(:stop_area_provider).stop_areas.create!(
              name: 'unknown',
              registration_number: 'unknown_code'
            )
          end

          it 'returns data in the cache' do
            is_expected.to be_nil
          end
        end
      end
    end

    describe '#find_ids' do
      subject { stop_areas.find_ids('provider_code', 'workbench_code', 'workgroup_code', 'unknown_code') }

      it 'returns the ids of all stop areas having these registration numbers' do
        is_expected.to eq(
          [
            context.stop_area(:provider_stop_area).id,
            context.stop_area(:workbench_stop_area).id,
            context.stop_area(:workgroup_stop_area).id
          ]
        )
      end

      with_response(on: :stop_areas) do
        it 'calls all response callbacks' do
          expect(callback).to receive(:callback).with(
            have_attributes(
              class: Import::Lookup::Response,
              source: :provider,
              code: 'provider_code',
              model_id: context.stop_area(:provider_stop_area).id,
              model: nil
            ),
            {}
          )
          expect(callback).to receive(:callback).with(
            have_attributes(
              class: Import::Lookup::Response,
              source: :workbench,
              code: 'workbench_code',
              model_id: context.stop_area(:workbench_stop_area).id,
              model: nil
            ),
            {}
          )
          expect(callback).to receive(:callback).with(
            have_attributes(
              class: Import::Lookup::Response,
              source: :workgroup,
              code: 'workgroup_code',
              model_id: context.stop_area(:workgroup_stop_area).id,
              model: nil
            ),
            {}
          )
          expect(callback).to receive(:callback).with(
            have_attributes(
              class: Import::Lookup::Response,
              source: :none,
              code: 'unknown_code',
              model_id: nil,
              model: nil
            ),
            {}
          )
          subject
        end
      end
    end

    describe '#find' do
      subject { stop_areas.find(code, **arguments) }

      context 'when code is blank' do
        let(:code) { '' }

        it { is_expected.to be_nil }
      end

      context 'when code is the registration number of a stop area in provider' do
        let(:code) { 'provider_code' }

        it 'returns the stop area in the provider having this registration number' do
          is_expected.to eq(context.stop_area(:provider_stop_area))
        end

        with_response(on: :stop_areas) do
          it 'calls response callback' do
            expect(callback).to receive(:callback).with(
              have_attributes(
                class: Import::Lookup::Response,
                source: :provider,
                code: 'provider_code',
                model_id: nil,
                model: context.stop_area(:provider_stop_area)
              ),
              arguments
            )
            subject
          end
        end

        context 'with cache' do
          before do
            stop_areas.find(code) # cache the response
            Chouette::StopArea.destroy_all
          end

          it 'returns data in the cache' do
            is_expected.to eq(context.stop_area(:provider_stop_area))
          end
        end
      end

      context 'when code is the registration number of a stop area in workbench' do
        let(:code) { 'workbench_code' }

        it 'returns the stop area in the workbench having this registration number' do
          is_expected.to eq(context.stop_area(:workbench_stop_area))
        end

        with_response(on: :stop_areas) do
          it 'calls response callback' do
            expect(callback).to receive(:callback).with(
              have_attributes(
                class: Import::Lookup::Response,
                source: :workbench,
                code: 'workbench_code',
                model_id: nil,
                model: context.stop_area(:workbench_stop_area)
              ),
              arguments
            )
            subject
          end
        end
      end

      context 'when code is the registration number of a stop area in workgroup' do
        let(:code) { 'workgroup_code' }

        it 'returns the stop area in the workgroup having this registration number' do
          is_expected.to eq(context.stop_area(:workgroup_stop_area))
        end

        with_response(on: :stop_areas) do
          it 'calls response callback' do
            expect(callback).to receive(:callback).with(
              have_attributes(
                class: Import::Lookup::Response,
                source: :workgroup,
                code: 'workgroup_code',
                model_id: nil,
                model: context.stop_area(:workgroup_stop_area)
              ),
              arguments
            )
            subject
          end
        end
      end

      context 'when code is unknown' do
        let(:code) { 'unknown_code' }

        it { is_expected.to be_nil }

        with_response(on: :stop_areas) do
          it 'calls response callback' do
            expect(callback).to receive(:callback).with(
              have_attributes(
                class: Import::Lookup::Response,
                source: :none,
                code: 'unknown_code',
                model_id: nil,
                model: nil
              ),
              arguments
            )
            subject
          end
        end

        context 'with cache' do
          before do
            stop_areas.find(code) # cache the response
            context.stop_area_provider(:stop_area_provider).stop_areas.create!(
              name: 'unknown',
              registration_number: 'unknown_code'
            )
          end

          it 'returns data in the cache' do
            is_expected.to be_nil
          end
        end
      end
    end

    describe '#find_by_id' do
      subject { stop_areas.find_by_id(id, **arguments) }

      let(:context) do
        Chouette.create do
          organisation :organisation, sso_attributes: { 'stop_area_providers' => 2.times.map(&:to_s) }
          workgroup owner: :organisation do
            workbench organisation: :organisation do
              stop_area :unknown_stop_area
            end
          end
          workgroup :workgroup, owner: :organisation do
            workbench organisation: :organisation do
              stop_area :workgroup_stop_area
            end

            workbench :workbench, organisation: :organisation do
              stop_area_provider objectid: 'FR1:OrganisationalUnit:0:' do
                stop_area :workbench_stop_area
              end
              stop_area_provider :stop_area_provider, objectid: 'FR1:OrganisationalUnit:1:' do
                stop_area :provider_stop_area
              end
            end
          end
        end
      end

      context 'when id is blank' do
        let(:id) { '' }

        it { is_expected.to be_nil }
      end

      context 'when id is the id of a stop area in provider' do
        let(:id) { context.stop_area(:provider_stop_area).id }

        it 'returns the stop area in the provider having this id' do
          is_expected.to eq(context.stop_area(:provider_stop_area))
        end

        with_response(on: :stop_areas) do
          it 'calls response callback' do
            expect(callback).to receive(:callback).with(
              have_attributes(
                class: Import::Lookup::Response,
                source: :provider,
                code: nil,
                model_id: nil,
                model: context.stop_area(:provider_stop_area)
              ),
              arguments
            )
            subject
          end
        end

        context 'with cache' do
          before do
            stop_areas.find_by_id(id) # rubocop:disable Rails/DynamicFindBy # cache the response
            Chouette::StopArea.destroy_all
          end

          it 'returns data in the cache' do
            is_expected.to eq(context.stop_area(:provider_stop_area))
          end
        end
      end

      context 'when id is the id of a stop area in workbench' do
        let(:id) { context.stop_area(:workbench_stop_area).id }

        it 'returns the stop area in the workbench having this id' do
          is_expected.to eq(context.stop_area(:workbench_stop_area))
        end

        with_response(on: :stop_areas) do
          it 'calls response callback' do
            expect(callback).to receive(:callback).with(
              have_attributes(
                class: Import::Lookup::Response,
                source: :workbench,
                code: nil,
                model_id: nil,
                model: context.stop_area(:workbench_stop_area)
              ),
              arguments
            )
            subject
          end
        end
      end

      context 'when id is the id of a stop area in workgroup' do
        let(:id) { context.stop_area(:workgroup_stop_area).id }

        it 'returns the stop area in the workgroup having this id' do
          is_expected.to eq(context.stop_area(:workgroup_stop_area))
        end

        with_response(on: :stop_areas) do
          it 'calls response callback' do
            expect(callback).to receive(:callback).with(
              have_attributes(
                class: Import::Lookup::Response,
                source: :workgroup,
                code: nil,
                model_id: nil,
                model: context.stop_area(:workgroup_stop_area)
              ),
              arguments
            )
            subject
          end
        end
      end

      context 'when id is unknown' do
        let(:id) { context.stop_area(:unknown_stop_area).id }

        it { is_expected.to be_nil }

        with_response(on: :stop_areas) do
          it 'calls response callback' do
            expect(callback).to receive(:callback).with(
              have_attributes(
                class: Import::Lookup::Response,
                source: :none,
                code: nil,
                model_id: nil,
                model: nil
              ),
              arguments
            )
            subject
          end
        end

        context 'with cache' do
          before do
            stop_areas.find_by_id(id) # rubocop:disable Rails/DynamicFindBy # cache the response
            context.stop_area(:unknown_stop_area).update!(
              stop_area_provider: context.stop_area_provider(:stop_area_provider)
            )
          end

          it 'returns data in the cache' do
            is_expected.to be_nil
          end
        end
      end
    end
  end

  describe '#lines' do
    subject(:lines) { lookup.lines }

    let(:context) do
      Chouette.create do
        organisation :organisation, sso_attributes: {
          'functional_scope' => %w[FR1:Line:0 FR1:Line:1 provider_code workbench_code]
        }
        workgroup owner: :organisation do
          workbench organisation: :organisation do
            line registration_number: 'workgroup_code'
            line registration_number: 'unknown_code'
          end
        end
        workgroup :workgroup, owner: :organisation do
          workbench organisation: :organisation do
            line :objectid_workgroup_line, objectid: 'workgroup_code'
            line registration_number: 'provider_code'
            line registration_number: 'workbench_code'
            line :workgroup_line, registration_number: 'workgroup_code'
          end

          workbench :workbench, organisation: :organisation do
            line_provider do
              line :objectid_workbench_line, objectid: 'workbench_code'
              line :workbench_line, objectid: 'FR1:Line:0', registration_number: 'workbench_code'
            end
            line_provider :line_provider do
              line :objectid_provider_line, objectid: 'provider_code', registration_number: 'other_code'
              line :provider_line, objectid: 'FR1:Line:1', registration_number: 'provider_code'
            end
          end
        end
      end
    end
    let(:line_provider) { context.line_provider(:line_provider) }

    describe '#find_id' do
      subject { lines.find_id(code, **arguments) }

      context 'when code is the registration number of a line in provider' do
        let(:code) { 'provider_code' }

        it 'returns the id of the line in the provider having this registration number' do
          is_expected.to eq(context.line(:provider_line).id)
        end

        with_response(on: :lines) do
          it 'calls response callback' do
            expect(callback).to receive(:callback).with(
              have_attributes(
                class: Import::Lookup::Response,
                source: :provider,
                code: 'provider_code',
                model_id: context.line(:provider_line).id,
                model: nil
              ),
              arguments
            )
            subject
          end
        end

        context 'with cache' do
          before do
            lines.find_id(code) # cache the response
            Chouette::Line.destroy_all
          end

          it 'returns data in the cache' do
            is_expected.to eq(context.line(:provider_line).id)
          end
        end

        context 'when override_internal_identifiers is true' do
          let(:override_internal_identifiers) { true }

          it 'returns the id of the line in the provider having this objectid' do
            is_expected.to eq(context.line(:objectid_provider_line).id)
          end
        end

        context 'when there is no line provider' do
          let(:line_provider) { nil }

          it 'returns the id of the line in the workbench having this registration number' do
            is_expected.to eq(context.line(:provider_line).id)
          end

          with_response(on: :lines) do
            it 'calls response callback' do
              expect(callback).to receive(:callback).with(
                have_attributes(
                  class: Import::Lookup::Response,
                  source: :workbench,
                  code: 'provider_code',
                  model_id: context.line(:provider_line).id,
                  model: nil
                ),
                arguments
              )
              subject
            end
          end
        end
      end

      context 'when code is the registration number of a line in workbench' do
        let(:code) { 'workbench_code' }

        it 'returns the id of the line in the workbench having this registration number' do
          is_expected.to eq(context.line(:workbench_line).id)
        end

        with_response(on: :lines) do
          it 'calls response callback' do
            expect(callback).to receive(:callback).with(
              have_attributes(
                class: Import::Lookup::Response,
                source: :workbench,
                code: 'workbench_code',
                model_id: context.line(:workbench_line).id,
                model: nil
              ),
              arguments
            )
            subject
          end
        end

        context 'when override_internal_identifiers is true' do
          let(:override_internal_identifiers) { true }

          it 'returns the id of the line in the workbench having this objectid' do
            is_expected.to eq(context.line(:objectid_workbench_line).id)
          end
        end
      end

      context 'when code is the registration number of a line in workgroup' do
        let(:code) { 'workgroup_code' }

        it 'returns the id of the line in the workgroup having this registration number' do
          is_expected.to eq(context.line(:workgroup_line).id)
        end

        with_response(on: :lines) do
          it 'calls response callback' do
            expect(callback).to receive(:callback).with(
              have_attributes(
                class: Import::Lookup::Response,
                source: :workgroup,
                code: 'workgroup_code',
                model_id: context.line(:workgroup_line).id,
                model: nil
              ),
              arguments
            )
            subject
          end
        end

        context 'when override_internal_identifiers is true' do
          let(:override_internal_identifiers) { true }

          it 'returns the id of the line in the workgroup having this objectid' do
            is_expected.to eq(context.line(:objectid_workgroup_line).id)
          end
        end
      end

      context 'when code is unknown' do
        let(:code) { 'unknown_code' }

        it { is_expected.to be_nil }
      end
    end
  end

  describe '#companies' do
    subject(:companies) { lookup.companies }

    let(:context) do
      Chouette.create do
        workgroup do
          workbench do
            company registration_number: 'workgroup_code'
            company registration_number: 'unknown_code'
          end
        end
        workgroup :workgroup do
          workbench do
            company :objectid_workgroup_company, objectid: 'workgroup_code'
            company :workgroup_company, registration_number: 'workgroup_code'
          end

          workbench :workbench do
            line_provider :line_provider do
              company :objectid_provider_company, objectid: 'provider_code', registration_number: 'other_code'
              company :provider_company, registration_number: 'provider_code'
            end
          end
        end
      end
    end
    let(:line_provider) { context.line_provider(:line_provider) }

    describe '#find_id' do
      subject { companies.find_id(code, **arguments) }

      context 'when code is the registration number of a company in provider' do
        let(:code) { 'provider_code' }

        it 'returns the id of the company in the provider having this registration number' do
          is_expected.to eq(context.company(:provider_company).id)
        end

        with_response(on: :companies) do
          it 'calls response callback' do
            expect(callback).to receive(:callback).with(
              have_attributes(
                class: Import::Lookup::Response,
                source: :provider,
                code: 'provider_code',
                model_id: context.company(:provider_company).id,
                model: nil
              ),
              arguments
            )
            subject
          end
        end

        context 'with cache' do
          before do
            companies.find_id(code) # cache the response
            Chouette::Company.destroy_all
          end

          it 'returns data in the cache' do
            is_expected.to eq(context.company(:provider_company).id)
          end
        end

        context 'when override_internal_identifiers is true' do
          let(:override_internal_identifiers) { true }

          it 'returns the id of the company in the provider having this objectid' do
            is_expected.to eq(context.company(:objectid_provider_company).id)
          end
        end

        context 'when there is no line provider' do
          let(:line_provider) { nil }

          it 'returns the id of the company in the workbench having this registration number' do
            is_expected.to eq(context.company(:provider_company).id)
          end

          with_response(on: :companies) do
            it 'calls response callback' do
              expect(callback).to receive(:callback).with(
                have_attributes(
                  class: Import::Lookup::Response,
                  source: :workbench,
                  code: 'provider_code',
                  model_id: context.company(:provider_company).id,
                  model: nil
                ),
                arguments
              )
              subject
            end
          end
        end
      end

      context 'when code is the registration number of a company in workgroup' do
        let(:code) { 'workgroup_code' }

        it 'returns the id of the company in the workgroup having this registration number' do
          is_expected.to eq(context.company(:workgroup_company).id)
        end

        with_response(on: :companies) do
          it 'calls response callback' do
            expect(callback).to receive(:callback).with(
              have_attributes(
                class: Import::Lookup::Response,
                source: :workbench, # workbench.lines is the same as workgroup.lines
                code: 'workgroup_code',
                model_id: context.company(:workgroup_company).id,
                model: nil
              ),
              arguments
            )
            subject
          end
        end

        context 'when override_internal_identifiers is true' do
          let(:override_internal_identifiers) { true }

          it 'returns the id of the company in the workgroup having this objectid' do
            is_expected.to eq(context.company(:objectid_workgroup_company).id)
          end
        end
      end

      context 'when code is unknown' do
        let(:code) { 'unknown_code' }

        it { is_expected.to be_nil }
      end
    end
  end

  describe '#line_notices' do
    subject(:line_notices) { lookup.line_notices }

    let(:context) do
      Chouette.create do
        workgroup do
          workbench do
            line_notice registration_number: 'workgroup_code'
            line_notice registration_number: 'unknown_code'
          end
        end
        workgroup :workgroup do
          workbench do
            line_notice :objectid_workgroup_line_notice, objectid: 'workgroup_code'
            line_notice :workgroup_line_notice, registration_number: 'workgroup_code'
          end

          workbench :workbench do
            line_provider :line_provider do
              line_notice :objectid_provider_line_notice, objectid: 'provider_code', registration_number: 'other_code'
              line_notice :provider_line_notice, registration_number: 'provider_code'
            end
          end
        end
      end
    end
    let(:line_provider) { context.line_provider(:line_provider) }

    describe '#find_id' do
      subject { line_notices.find_id(code, **arguments) }

      context 'when code is the registration number of a line notice in provider' do
        let(:code) { 'provider_code' }

        it 'returns the id of the line notice in the provider having this registration number' do
          is_expected.to eq(context.line_notice(:provider_line_notice).id)
        end

        with_response(on: :line_notices) do
          it 'calls response callback' do
            expect(callback).to receive(:callback).with(
              have_attributes(
                class: Import::Lookup::Response,
                source: :provider,
                code: 'provider_code',
                model_id: context.line_notice(:provider_line_notice).id,
                model: nil
              ),
              arguments
            )
            subject
          end
        end

        context 'with cache' do
          before do
            line_notices.find_id(code) # cache the response
            Chouette::LineNotice.destroy_all
          end

          it 'returns data in the cache' do
            is_expected.to eq(context.line_notice(:provider_line_notice).id)
          end
        end

        context 'when override_internal_identifiers is true' do
          let(:override_internal_identifiers) { true }

          it 'returns the id of the line notice in the provider having this objectid' do
            is_expected.to eq(context.line_notice(:objectid_provider_line_notice).id)
          end
        end

        context 'when there is no line provider' do
          let(:line_provider) { nil }

          it 'returns the id of the line notice in the workbench having this registration number' do
            is_expected.to eq(context.line_notice(:provider_line_notice).id)
          end

          with_response(on: :line_notices) do
            it 'calls response callback' do
              expect(callback).to receive(:callback).with(
                have_attributes(
                  class: Import::Lookup::Response,
                  source: :workbench,
                  code: 'provider_code',
                  model_id: context.line_notice(:provider_line_notice).id,
                  model: nil
                ),
                arguments
              )
              subject
            end
          end
        end
      end

      context 'when code is the registration number of a line notice in workgroup' do
        let(:code) { 'workgroup_code' }

        it 'returns the id of the line notice in the workgroup having this registration number' do
          is_expected.to eq(context.line_notice(:workgroup_line_notice).id)
        end

        with_response(on: :line_notices) do
          it 'calls response callback' do
            expect(callback).to receive(:callback).with(
              have_attributes(
                class: Import::Lookup::Response,
                source: :workbench, # workbench.lines is the same as workgroup.lines
                code: 'workgroup_code',
                model_id: context.line_notice(:workgroup_line_notice).id,
                model: nil
              ),
              arguments
            )
            subject
          end
        end

        context 'when override_internal_identifiers is true' do
          let(:override_internal_identifiers) { true }

          it 'returns the id of the line notice in the workgroup having this objectid' do
            is_expected.to eq(context.line_notice(:objectid_workgroup_line_notice).id)
          end
        end
      end

      context 'when code is unknown' do
        let(:code) { 'unknown_code' }

        it { is_expected.to be_nil }
      end
    end
  end

  describe '#booking_arrangements' do
    subject(:booking_arrangements) { lookup.booking_arrangements }

    let(:context) do
      Chouette.create do
        workgroup :workgroup do
          code_space :code_space, short_name: 'code_space'
          code_space :other_code_space, short_name: 'other_code_space'

          workbench :workbench do
            line_provider do
              booking_arrangement codes: { code_space: 'provider_code' }
              booking_arrangement codes: { code_space: 'unknown_code' }
            end
            line_provider :line_provider do
              booking_arrangement :objectid_provider_booking_arrangement, objectid: 'provider_code'
              booking_arrangement codes: { code_space: 'other_code', other_code_space: 'provider_code' }
              booking_arrangement :provider_booking_arrangement, codes: { code_space: 'provider_code' }
            end
          end
        end
      end
    end
    let(:code_space) { context.code_space(:code_space) }
    let(:line_provider) { context.line_provider(:line_provider) }

    describe '#find_id' do
      subject { booking_arrangements.find_id(code, **arguments) }

      context 'when code is the code of a booking arrangement in provider' do
        let(:code) { 'provider_code' }

        it 'returns the id of the booking arrangement in the provider having this code' do
          is_expected.to eq(context.booking_arrangement(:provider_booking_arrangement).id)
        end

        with_response(on: :booking_arrangements) do
          it 'calls response callback' do
            expect(callback).to receive(:callback).with(
              have_attributes(
                class: Import::Lookup::Response,
                source: :provider,
                code: 'provider_code',
                model_id: context.booking_arrangement(:provider_booking_arrangement).id,
                model: nil
              ),
              arguments
            )
            subject
          end
        end

        context 'with cache' do
          before do
            booking_arrangements.find_id(code) # cache the response
            Chouette::StopArea.destroy_all
          end

          it 'returns data in the cache' do
            is_expected.to eq(context.booking_arrangement(:provider_booking_arrangement).id)
          end
        end

        context 'when override_internal_identifiers is true' do
          let(:override_internal_identifiers) { true }

          it 'returns the id of the booking arrangement in the provider having this objectid' do
            is_expected.to eq(context.booking_arrangement(:objectid_provider_booking_arrangement).id)
          end
        end

        context 'when there is no line provider' do
          let(:line_provider) { nil }

          it { is_expected.to be_nil }
        end
      end

      context 'when code is unknown' do
        let(:code) { 'unknown_code' }

        it { is_expected.to be_nil }
      end
    end
  end

  describe '#shapes' do
    subject(:shapes) { lookup.shapes }

    let(:context) do
      Chouette.create do
        workgroup :workgroup do
          code_space :code_space, short_name: 'code_space'
          code_space :other_code_space, short_name: 'other_code_space'

          workbench :workbench do
            shape_provider do
              shape codes: { code_space: 'provider_code' }
              shape codes: { code_space: 'unknown_code' }
            end
            shape_provider :shape_provider do
              shape codes: { code_space: 'other_code', other_code_space: 'provider_code' }
              shape :provider_shape, codes: { code_space: 'provider_code' }
            end
          end
        end
      end
    end
    let(:code_space) { context.code_space(:code_space) }
    let(:shape_provider) { context.shape_provider(:shape_provider) }

    describe '#find_id' do
      subject { shapes.find_id(code, **arguments) }

      context 'when code is the code of a shape in provider' do
        let(:code) { 'provider_code' }

        it 'returns the id of the shape in the provider having this code' do
          is_expected.to eq(context.shape(:provider_shape).id)
        end

        with_response(on: :shapes) do
          it 'calls response callback' do
            expect(callback).to receive(:callback).with(
              have_attributes(
                class: Import::Lookup::Response,
                source: :provider,
                code: 'provider_code',
                model_id: context.shape(:provider_shape).id,
                model: nil
              ),
              arguments
            )
            subject
          end
        end

        context 'with cache' do
          before do
            shapes.find_id(code) # cache the response
            Shape.destroy_all
          end

          it 'returns data in the cache' do
            is_expected.to eq(context.shape(:provider_shape).id)
          end
        end

        context 'when there is no shape provider' do
          let(:shape_provider) { nil }

          it { is_expected.to be_nil }
        end
      end

      context 'when code is unknown' do
        let(:code) { 'unknown_code' }

        it { is_expected.to be_nil }
      end
    end
  end
end

RSpec.describe Import::Lookup::Referential do
  let(:lookup) { Import::Lookup.referential(import) }

  let(:code_space) { context.code_space(:code_space) }
  let(:referential) { context.referential }
  let(:import) { double('import', code_space: code_space, referential: referential) }
  let(:arguments) { { arg1: 'v1', arg2: 'v2' } }

  before { referential.switch }

  describe '#time_tables' do
    subject(:time_tables) { lookup.time_tables }

    let(:context) do
      Chouette.create do
        code_space :code_space, short_name: 'code_space'
        code_space :other_code_space, short_name: 'other_code_space'

        referential do
          time_table codes: { code_space: 'other_code', other_code_space: 'code' }
          time_table :time_table, codes: { code_space: 'code' }
        end
      end
    end

    describe '#find_id' do
      subject { time_tables.find_id(code, **arguments) }

      context 'when code is blank' do
        let(:code) { '' }

        it { is_expected.to be_nil }
      end

      context 'when code is the code of a time table in referential' do
        let(:code) { 'code' }

        it 'returns the id of the time table in the referential having this code' do
          is_expected.to eq(context.time_table(:time_table).id)
        end
      end

      context 'when code is unknown' do
        let(:code) { 'unknown_code' }

        it { is_expected.to be_nil }
      end
    end

    describe '#find' do
      subject { time_tables.find(code, **arguments) }

      context 'when code is blank' do
        let(:code) { '' }

        it { is_expected.to be_nil }
      end

      context 'when code is the code of a time table in referential' do
        let(:code) { 'code' }

        it 'returns the time table in the referential having this code' do
          is_expected.to eq(context.time_table(:time_table))
        end
      end

      context 'when code is unknown' do
        let(:code) { 'unknown_code' }

        it { is_expected.to be_nil }
      end
    end

    describe '#find_by_id' do
      subject { time_tables.find_by_id(id, **arguments) }

      context 'when id is blank' do
        let(:id) { '' }

        it { is_expected.to be_nil }
      end

      context 'when id is the id of a time table in referential' do
        let(:id) { context.time_table(:time_table).id }

        it 'returns the time table in the referential having this id' do
          is_expected.to eq(context.time_table(:time_table))
        end
      end

      context 'when id is unknown' do
        let(:id) { Chouette::TimeTable.maximum(:id) + 1 }

        it { is_expected.to be_nil }
      end
    end
  end

  describe '#routes' do
    subject(:routes) { lookup.routes }

    let(:context) do
      Chouette.create do
        code_space :code_space, short_name: 'code_space'
        code_space :other_code_space, short_name: 'other_code_space'

        referential do
          route codes: { code_space: 'other_code', other_code_space: 'code' }
          route :route, codes: { code_space: 'code' }
        end
      end
    end

    describe '#find_id' do
      subject { routes.find_id(code, **arguments) }

      context 'when code is the code of a route in referential' do
        let(:code) { 'code' }

        it 'returns the id of the route in the referential having this code' do
          is_expected.to eq(context.route(:route).id)
        end
      end

      context 'when code is unknown' do
        let(:code) { 'unknown_code' }

        it { is_expected.to be_nil }
      end
    end
  end
end
