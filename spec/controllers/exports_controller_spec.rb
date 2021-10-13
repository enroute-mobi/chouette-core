RSpec.describe ExportsController, :type => :controller do

  login_user

  let(:context) do
      Chouette.create do
        # To match organisation used by login_user
        organisation = Organisation.find_by_code('first')
        workgroup owner: organisation, export_types: ['Export::Gtfs'] do
          workbench organisation: organisation do
            referential
          end
        end
      end
    end

    let(:referential) { context.referential }
    let(:export) { Export::Gtfs.create!(name: "Test", creator: 'test', referential: referential, workgroup: workgroup, workbench: workbench) }

    let(:workbench) { referential.workbench }
    let(:workgroup) { referential.workgroup }

    context "with #{parent} parent" do
      let(:parent_params) { { workbench_id: workbench.id, workgroup_id: workbench.workgroup_id } }

      describe "GET index" do
        let(:request){ get :index, params: parent_params }

        it "should be successful" do
          expect(request).to be_successful
        end
      end

      describe 'GET #new' do
        it 'should be successful if authorized' do
          get :new, params: parent_params
          expect(response).to be_successful
        end

        it 'should be unsuccessful unless authorized' do
          remove_permissions('exports.create', from_user: @user, save: true)
          get :new, params: parent_params
          expect(response).not_to be_successful
        end
      end

      describe "GET #show" do
        it 'should be successful' do
          get :show, params: parent_params.merge({ id: export.id })
          expect(response).to be_successful
        end

        context "in JSON format" do
          let(:export) { create :gtfs_export, workbench: workbench  }
          it 'should be successful' do
            get :show, params: parent_params.merge({ id: export.id, format: :json })
            expect(response).to be_successful
          end
        end
      end

      describe "POST #create" do
        let(:params){ { name: "foo" } }
        let(:request){ post :create, params: parent_params.merge({ export: params })}
        it 'should create no objects' do
          expect{request}.to_not change{Export::Gtfs.count}
        end

        context "with all options" do
          let(:params){parent_params.merge({
            name: "foo",
            type: "Export::Gtfs",
            referential_id: first_referential.id,
            creator: 'Test',
            options: { duration: 12 }
          })}

          it 'should be successful' do
            expect{request}.to change { Export::Gtfs.count }.by(1)
          end
        end

        context "with missing options" do
          let(:params){{
            referential_id: first_referential.id,
            type: "Export::Gtfs"
          }}

          it 'should be unsuccessful' do
            expect{request}.to change{Export::Gtfs.count}.by(0)
          end
        end

        context "with wrong type" do
          let(:params){{
            name: "foo",
            type: "Export::Foo"
          }}

          it 'should be unsuccessful' do
            expect{request}.to raise_error ActiveRecord::SubclassNotFound
          end
        end
      end

      describe 'POST #upload' do
        context "with the token" do
          it 'should be successful' do
            post :upload, params: parent_params.merge({ id: export.id, token: export.token_upload })
            expect(response).to be_successful
          end
        end

        context "without the token" do
          it 'should be unsuccessful' do
            post :upload, params: parent_params.merge({ id: export.id, token: "foo" })
            expect(response).to_not be_successful
          end
        end
      end

    end

    describe ExportsController::Search do
      let(:scope) { double }
      subject(:search) { ExportsController::Search.new scope }

      describe "validation" do
        context "when period is not valid" do
          before { allow(search).to receive(:period).and_return(double("valid?" => false)) }
          it { is_expected.to_not be_valid }
        end
        context "when period is valid" do
          before { allow(search).to receive(:period).and_return(double("valid?" => true)) }
          it { is_expected.to be_valid }
        end
      end

      describe "#period" do
        subject { search.period }

        context "when no start and end dates are defined" do
          before { search.start_date = search.end_date = nil }
          it { is_expected.to be_nil }
        end

        context "when start date is defined" do
          before { search.start_date = Time.zone.today }
          it { is_expected.to have_same_attributes(:start_date, than: search) }
        end

        context "when end date is defined" do
          before { search.end_date = Time.zone.today }
          it { is_expected.to have_same_attributes(:end_date, than: search) }
        end
      end

      describe "#candidate_statuses" do
        subject { search.candidate_statuses }


        Operation::UserStatus.all.each do |user_status|
          it "includes user status #{user_status}" do
            is_expected.to include(user_status)
          end
        end
      end

      describe "#candidate_workbenches" do
        subject { search.candidate_workbenches }

        context "when no workgroup is associated" do
          before { search.workgroup = nil }
          it { is_expected.to be_empty }
        end

        context "when a workgroup is defined" do
          before { search.workgroup = double(workbenches: double("Workgroup workbenches")) }
          it { is_expected.to eq(search.workgroup.workbenches) }
        end
      end

      describe "#workbenches" do
        subject { search.workbenches }

        context "when the Search is associated to a Workgroup" do
          let(:context) do
            Chouette.create do
              workgroup(:first) { workbench }
              workgroup(:other) { workbench }
            end
          end

          let(:workgroup) { context.workgroup(:first) }
          let(:search) { ExportsController::Search.new scope, {}, workgroup: workgroup }

          context "when workbench_ids is nil" do
            before { search.workbench_ids = nil }
            it { is_expected.to be_empty }
          end

          context "when workbench_ids is empty" do
            before { search.workbench_ids = [] }
            it { is_expected.to be_empty }
          end

          context "when workbench_ids contains the Workbench identifier from the associated Workgroup" do
            let(:workbench) { workgroup.workbenches.first }
            before { search.workbench_ids = [ workbench.id ] }

            it "includes this Workbench" do
              is_expected.to include(workbench)
            end
          end

          context "when workbench_ids contains the Workbench identifier from another Workgroup" do
            let(:workbench) { context.workgroup(:other).workbenches.first }
            before { search.workbench_ids = [ workbench.id ] }

            it "doesn't include this Workbench" do
              is_expected.to_not include(workbench)
            end
          end
        end

        context "when the Search isn't associated to a Workgroup" do
          it { is_expected.to be_empty }
        end
      end

      describe "#query" do

        it { is_expected.to have_same_attributes(:scope, than: search) }

        describe "build" do
          let(:query) { Query::Mock.new(scope) }

          before do
            allow(Query::Export).to receive(:new).and_return(query)
          end

          it "uses Search workbenches" do
            allow(search).to receive(:workbenches).and_return(double)
            expect(query).to receive(:workbenches).with(search.workbenches).and_return(query)
            search.query
          end

          it "uses Search name as text" do
            search.name = "dummy"
            expect(query).to receive(:text).with(search.name).and_return(query)
            search.query
          end

          it "uses Search statuses as user statuses" do
            allow(search).to receive(:statuses).and_return(double)
            expect(query).to receive(:user_statuses).with(search.statuses).and_return(query)
            search.query
          end

          it "uses Search period" do
            allow(search).to receive(:period).and_return(double)
            expect(query).to receive(:in_period).with(search.period).and_return(query)
            search.query
          end
        end
      end
    end
end
