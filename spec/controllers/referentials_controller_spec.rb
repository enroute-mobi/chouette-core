describe ReferentialsController, :type => :controller do

  login_user

  let(:referential) { Referential.first }
  let(:organisation) { create :organisation }
  let(:other_referential) { create :referential, organisation: organisation }

  describe "GET new" do
    let(:request){ get :new, workbench_id: referential.workbench_id }
    before{ request }

    it 'returns http success' do
      expect(response).to have_http_status(200)
    end

    context "when cloning another referential" do
      let(:source){ referential }
      let(:request){ get :new, workbench_id: referential.workbench_id, from: source.id }

      it 'returns http success' do
        expect(response).to have_http_status(200)
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

  describe 'PUT archive' do
    context "user's organisation matches referential's organisation" do
      it 'returns http success' do
        put :archive, id: referential.id
        expect(response).to have_http_status(302)
      end
    end

    context "user's organisation doesn't match referential's organisation" do
      it 'raises a ActiveRecord::RecordNotFound' do
        expect { put :archive, id: other_referential.id }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe 'GET select_compliance_control_set' do
    it 'gets compliance control set for current organisation' do
      compliance_control_set = create(:compliance_control_set, organisation: @user.organisation)
      create(:compliance_control_set)
      get :select_compliance_control_set, id: referential.id
      expect(assigns[:compliance_control_sets]).to eq([compliance_control_set])
    end
  end

  describe "POST #validate" do
    it "displays a flash message" do
      post :validate, id: referential.id, params: {
        compliance_control_set: create(:compliance_control_set).id
      }

      expect(controller).to set_flash[:notice].to(
        I18n.t('notice.referentials.validate')
      )
    end
  end

  describe "GET #new" do
    context "when duplicating" do
      let(:workbench){ create :workbench}
      let(:request){
        get :new,
          workbench_id: workbench.id,
          from: referential.id
      }

      it "duplicates the given referential" do
        request
        new_referential = assigns(:referential)
        expect(new_referential.line_referential).to eq referential.line_referential
        expect(new_referential.stop_area_referential).to eq referential.stop_area_referential
        expect(new_referential.objectid_format).to eq referential.objectid_format
        expect(new_referential.prefix).to eq referential.prefix
        expect(new_referential.slug).to be_nil
        expect(new_referential.workbench).to eq workbench
      end
    end
  end

  describe "POST #create" do
    let(:workbench){ create :workbench}
    context "when duplicating" do
      let(:request){
        post :create,
        workbench_id: workbench.id,
        referential: {
          name: 'Duplicated',
          created_from_id: referential.id,
          stop_area_referential: referential.stop_area_referential,
          line_referential: referential.line_referential,
          objectid_format: referential.objectid_format,
          workbench_id: referential.workbench_id
        }
      }

      it "creates the new referential" do
        expect{request}.to change{Referential.count}.by 1
        expect(Referential.last.name).to eq "Duplicated"
      end

      it "displays a flash message" do
        request
        expect(controller).to set_flash[:notice].to(
          I18n.t('notice.referentials.duplicate')
        )
      end
    end
  end
end
