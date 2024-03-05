# frozen_string_literal: true

describe ReferentialsController, type: :controller do
  login_user

  let(:referential) { Referential.first }
  let(:organisation) { @user.organisation }
  let(:other_referential) { create :referential, organisation: organisation }
  let(:workbench) { create :workbench, organisation: organisation }

  describe "GET new" do
    let(:request){ get :new, params: { workbench_id: workbench.id }}

    it_behaves_like 'checks current_organisation'

    context "when cloning another referential" do
      before{ request }
      let(:source){ referential }
      let(:request){ get :new, params: { workbench_id: workbench.id, from: source.id }}

      it 'returns http success' do
        expect(response).to have_http_status(200)
      end

      it "duplicates the given referential" do
        new_referential = assigns(:referential)
        expect(new_referential.line_referential).to eq source.line_referential
        expect(new_referential.stop_area_referential).to eq source.stop_area_referential
        expect(new_referential.objectid_format).to eq source.objectid_format
        expect(new_referential.prefix).to eq source.prefix
        expect(new_referential.slug).to be_nil
        expect(new_referential.workbench).to eq workbench
      end

      context "when the referential is in another organisation but accessible by the user" do
        let(:source){ create(:workbench_referential) }
        before do
          source.workbench.update_attribute :workgroup_id, referential.workbench.workgroup_id
        end

        it 'returns http forbidden' do
          expect(response).to have_http_status(403)
        end
      end

      context "when the referential is not accessible by the user" do
        let(:source){ create(:workbench_referential) }
        it 'returns http forbidden' do
          expect(response).to have_http_status(403)
        end
      end
    end
  end

  describe "POST #create" do
    let(:from_current_offer) { '0' }
    let(:urgent) { '0' }
    let(:metadatas_attributes){
      [
        {
          lines: [referential.line_referential.lines.last.id],
          periods_attributes: {
            '0' => {
              "begin"=>"2016-09-19",
              "end" => "2016-10-19",
            }
          }
        }
      ]
    }

    before do
      create :line, line_referential: referential.line_referential
    end

    context 'when creating a new referential' do
      let(:request){
        post :create,
        params: {
          workbench_id: workbench.id,
          referential: {
            name: 'new one',
            stop_area_referential: referential.stop_area_referential,
            line_referential: referential.line_referential,
            objectid_format: referential.objectid_format,
            workbench_id: referential.workbench_id,
            from_current_offer: from_current_offer,
            urgent: urgent,
            metadatas_attributes: metadatas_attributes
          }
        }
      }

      it "creates the new referential" do
        expect{ request }.to change{ Referential.count }.by 1
        expect(Referential.last.name).to eq "new one"
        expect(Referential.last.state).to eq :active
        expect(Referential.last.created_from).to be_nil
      end

      context "urgent" do
        let(:urgent) { 'true' }

        it "does not mark the referential as urgent" do
          request
          expect(Referential.last.contains_urgent_offer?).to be_falsy
        end
      end

      with_permission 'referentials.flag_urgent' do
        context "urgent" do
          let(:urgent) { 'true' }

          it "marks the referential as urgent" do
            request
            expect(Referential.last.contains_urgent_offer?).to be_truthy
          end
        end
      end
    end
    context "when duplicating" do
      let(:request){
        post :create,
        params: {
          workbench_id: workbench.id,
          referential: {
            name: 'Duplicated',
            created_from_id: referential.id,
            stop_area_referential: referential.stop_area_referential,
            line_referential: referential.line_referential,
            objectid_format: referential.objectid_format,
            workbench_id: referential.workbench_id,
            from_current_offer: from_current_offer,
            urgent: urgent,
            metadatas_attributes: metadatas_attributes
          }
        }
      }

      it "creates the new referential" do
        expect{request}.to change{Referential.count}.by 1
        expect(Referential.last.name).to eq "Duplicated"
        expect(Referential.last.state).to eq :pending
      end

      it "should not clone the current offer" do
        @create_from_current_offer = false
        allow_any_instance_of(Referential).to receive(:create_from_current_offer){ @create_from_current_offer = true }
        request
        expect(@create_from_current_offer).to be_falsy
      end

      it "displays a flash message" do
        request
        expect(controller).to set_flash[:notice].to(
          I18n.t('notice.referentials.duplicate')
        )
      end

      context "from_current_offer" do
        let(:from_current_offer) { 'true' }

        it "should clone the current offer" do
          @create_from_current_offer = false
          allow_any_instance_of(Referential).to receive(:create_from_current_offer){ @create_from_current_offer = true }
          request
          expect(@create_from_current_offer).to be_truthy
        end
      end

      context "urgent" do
        let(:urgent) { 'true' }

        it "does not mark the referential as urgent" do
          request
          expect(Referential.last.contains_urgent_offer?).to be_falsy
        end
      end

      with_permission 'referentials.flag_urgent' do
        context "urgent" do
          let(:urgent) { 'true' }

          it "marks the referential as urgent" do
            request
            expect(Referential.last.contains_urgent_offer?).to be_truthy
          end
        end
      end
    end
  end

  describe 'GET show' do
    before(:each) do
      line = create(:line, line_referential: referential.line_referential)
      referential.metadatas << create(:referential_metadata, lines: [line])
      allow_any_instance_of(WorkbenchScopes::All).to receive(:lines_scope).and_return Chouette::Line.none
    end

    context 'referential with lines outside functional scope' do
      it 'does displays a warning message to the user' do
        out_scope_lines = referential.lines_outside_of_scope
        message = I18n.t("referentials.show.lines_outside_of_scope", count: out_scope_lines.count, lines: out_scope_lines.pluck(:name).join(", "), organisation: referential.organisation.name)

        get :show, params: { id: referential.id }

        expect(out_scope_lines.count).to eq(1)
        expect(referential.organisation.lines_scope).to be_nil
        expect(flash[:warning]).to be
        expect(flash[:warning]).to eq(message)
      end
    end
  end

  describe 'PUT #update' do
    let(:referential_workbench) { workbench }
    let(:referential) do
      create(:referential, workbench: referential_workbench, organisation: referential_workbench.organisation)
    end
    let(:request) { put :update, params: { id: referential.id, referential: { name: 'changed' } } }

    it_behaves_like 'checks current_organisation', success_code: 302

    context 'when the referential workbench has a different organisation from user' do
      let(:context) do
        Chouette.create do
          workgroup do
            workbench :expected_workbench, organisation: Organisation.find_by(code: 'first')
            workbench do
              referential :through_workgroup_referential
            end
          end
        end
      end
      let(:referential) { context.referential(:through_workgroup_referential) }

      it 'should respond with FORBIDDEN' do
        expect(request).to render_template('errors/forbidden')
      end

      it 'assigns @workbench as the sole workbench having the same organisation as the user' do
        request
        expect(assigns(:workbench)).to eq(context.workbench(:expected_workbench))
      end
    end
  end

  describe 'PUT #archive' do
    let(:referential) { create(:referential, workbench: workbench, organisation: organisation) }
    let(:request) { put :archive, params: { id: referential.id } }
    it_behaves_like 'checks current_organisation', success_code: 302
  end
end
