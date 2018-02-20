RSpec.describe ReferentialDecorator, type: [:helper, :decorator] do
  include Support::DecoratorHelpers

  let( :workbench ){ build_stubbed :workbench }
  let( :object ){ build_stubbed :referential, workbench: workbench }
  let( :referential ){ object }
  let( :user ){ build_stubbed :user }

  describe 'delegation' do
    it 'delegates all' do
      %i{xx xxx anything save!}.each do |method|
        expect( object ).to receive(method)
      end
      # Almost as powerful as Quicktest :P
      %i{xx xxx anything save!}.each do |method|
        subject.send method
      end
    end
  end

  describe 'action links for' do

    context 'unarchived referential' do
      context 'no rights' do
        it 'has only show and Calendar actions' do
          expect_action_link_hrefs.to eq([[object], referential_time_tables_path(object)])
        end
      end

      context 'all rights and different organisation' do

        let( :user ){ build_stubbed :allmighty_user }

        it 'has only default actions' do
          expect_action_link_elements.to eq ["Consulter", "Calendriers", "Dupliquer"]
          expect_action_link_hrefs.to eq([
            [object],
            referential_time_tables_path(object),
            new_workbench_referential_path(referential.workbench, from: object.id)
          ])
        end
      end
      context 'all rights and same organisation' do

        let( :user ){ build_stubbed :allmighty_user, organisation: referential.organisation }
        let( :action){ :index }
        context "on index" do
          it 'has corresponding actions' do
            expect_action_link_elements(action).to eq ["Consulter", "Editer", "Calendriers", "Dupliquer", "Valider", "Conserver","<span class=\"fa fa-trash mr-xs\"></span>Supprimer"]
            expect_action_link_hrefs(action).to eq([
              [object],
              [:edit, object],
              referential_time_tables_path(object),
              new_workbench_referential_path(referential.workbench, from: object.id),
              select_compliance_control_set_referential_path(object),
              archive_referential_path(object),
              referential_path(object)
            ])
          end
        end

        context "on show" do
          let( :action){ :show }
          it 'has corresponding actions' do
            expect_action_link_elements(action).to eq ["Editer", "Calendriers", "Dupliquer", "Valider", "Conserver", "Purger", "<span class=\"fa fa-trash mr-xs\"></span>Supprimer"]
            expect_action_link_hrefs(action).to eq([
              [:edit, object],
              referential_time_tables_path(object),
              new_workbench_referential_path(referential.workbench, from: object.id),
              select_compliance_control_set_referential_path(object),
              archive_referential_path(object),
              "#",
              referential_path(object)
            ])
          end
        end
      end
    end

    context 'archived referential' do
      before { referential.archived_at = 42.seconds.ago }
      context 'no rights' do
        it 'has only ahow and calendar actions' do
          expect_action_link_hrefs.to eq([[object], referential_time_tables_path(object)])
        end
      end

      context 'all rights and different organisation' do
        let( :user ){ build_stubbed :allmighty_user }
        it 'has only default actions' do
          expect_action_link_elements.to eq ["Consulter", "Calendriers", "Dupliquer"]
          expect_action_link_hrefs.to eq([
            [object],
            referential_time_tables_path(object),
            new_workbench_referential_path(referential.workbench, from: object.id)
          ])
        end
      end
    end
  end


end
