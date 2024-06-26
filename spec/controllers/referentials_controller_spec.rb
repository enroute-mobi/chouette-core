# frozen_string_literal: true

describe ReferentialsController, type: :controller do
  login_user

  let(:context) do
    Chouette.create do
      workbench :workbench, organisation: Organisation.find_by(code: 'first') do
        referential :referential
      end
    end
  end
  let(:workbench) { context.workbench(:workbench) }
  let(:referential) { context.referential(:referential) }

  describe "GET new" do
    let(:request){ get :new, params: { workbench_id: workbench.id }}

    it 'returns http success' do
      expect(request).to have_http_status(:ok)
    end

    context "when cloning another referential" do
      let(:context) do
        Chouette.create do
          workgroup do
            workbench(:workbench, organisation: Organisation.find_by(code: 'first')) do
              referential :referential
            end
            workbench do
              referential :through_workgroup_referential
            end
          end
          workgroup do
            workbench do
              referential :other_referential
            end
          end
        end
      end
      let(:request) { get :new, params: { workbench_id: workbench.id, from: referential.id } }

      before { request }

      it 'returns http success' do
        expect(response).to have_http_status(:ok)
      end

      it "duplicates the given referential" do
        new_referential = assigns(:referential)
        expect(new_referential.line_referential).to eq referential.line_referential
        expect(new_referential.stop_area_referential).to eq referential.stop_area_referential
        expect(new_referential.objectid_format).to eq referential.objectid_format
        expect(new_referential.prefix).to eq referential.prefix
        expect(new_referential.slug).to be_nil
        expect(new_referential.workbench).to eq workbench
      end

      context "when the referential is in another organisation but accessible by the user" do
        let(:referential) { context.referential(:through_workgroup_referential) }

        it 'returns http success' do
          expect(response).to have_http_status(:ok)
        end
      end

      context "when the referential is not accessible by the user" do
        let(:referential) { context.referential(:other_referential) }

        it 'returns http forbidden' do
          expect(response).to have_http_status(:forbidden)
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
        referential # create referential before calling request
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
        referential # create referential before calling request
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
    let(:context) do
      Chouette.create do
        workgroup do
          workbench(:workbench, organisation: Organisation.find_by(code: 'first')) do
            referential :referential
          end
          workbench(:other_workbench) do
            referential :through_workgroup_referential
          end
        end
        workgroup do
          workbench do
            referential :other_referential
          end
        end
      end
    end
    let(:request) { get :show, params: { workbench_id: workbench.id, id: referential.id } }

    context 'when the referential workbench has the same organisation as user' do
      it 'returns http success' do
        expect(request).to have_http_status(:ok)
      end

      context 'when referential with lines outside functional scope' do
        before(:each) do
          allow_any_instance_of(WorkbenchScopes::All).to receive(:lines_scope).and_return Chouette::Line.none
          workbench.workgroup.output.referentials << referential
        end

        it 'does displays a warning message to the user' do
          request

          out_scope_lines = referential.lines_outside_of_scope
          message = I18n.t("referentials.show.lines_outside_of_scope", count: out_scope_lines.count, lines: out_scope_lines.pluck(:name).join(", "), organisation: referential.organisation.name)

          expect(out_scope_lines.count).to eq(1)
          expect(referential.organisation.lines_scope).to be_nil
          expect(flash[:warning]).to be
          expect(flash[:warning]).to eq(message)
        end
      end
    end

    context 'when the referential workbench has a different organisation from user' do
      let(:referential) { context.referential(:through_workgroup_referential) }

      it 'returns http success' do
        expect(request).to have_http_status(:ok)
      end
    end

    context 'when the referential is unrelated to user organisation' do
      let(:referential) { context.referential(:other_referential) }

      it 'should respond with NOT FOUND' do
        expect(request).to have_http_status(:not_found)
      end
    end

    context 'when the workbench is unrelated to user organisation' do
      let(:workbench) { context.workbench(:other_workbench) }

      it 'should respond with NOT FOUND' do
        expect(request).to have_http_status(:not_found)
      end
    end
  end

  describe 'PUT #update' do
    let(:request) do
      put :update, params: { workbench_id: workbench.id, id: referential.id, referential: { name: 'changed' } }
    end

    it 'redirects' do
      expect(request).to have_http_status(:redirect)
    end

    context 'when the referential workbench has a different organisation from user' do
      let(:context) do
        Chouette.create do
          workgroup do
            workbench :expected_workbench, organisation: Organisation.find_by(code: 'first')
            workbench :other_workbench do
              referential :through_workgroup_referential
            end
          end
        end
      end
      let(:workbench) { context.workbench(:expected_workbench) }
      let(:referential) { context.referential(:through_workgroup_referential) }

      it 'should respond with FORBIDDEN' do
        expect(request).to render_template('errors/forbidden')
      end

      context 'when the workbench is unrelated to user organisation' do
        let(:workbench) { context.workbench(:other_workbench) }

        it 'should respond with NOT FOUND' do
          expect(request).to have_http_status(:not_found)
        end
      end
    end
  end

  describe 'PUT #archive' do
    let(:request) { put :archive, params: { workbench_id: workbench.id, id: referential.id } }

    it 'redirects' do
      expect(request).to have_http_status(:redirect)
    end
  end
end
