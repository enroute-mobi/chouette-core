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
          expect_action_link_hrefs.to match_array([[object], referential_time_tables_path(object)])
        end
      end

      context 'all rights and different organisation' do

        let( :user ){ build_stubbed :allmighty_user }

        it 'has only default actions' do
          expect_action_link_elements.to match_array ["Consulter", "Calendriers", "Dupliquer"]
          expect_action_link_hrefs.to match_array([
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
            expect_action_link_elements(action).to match_array ["Consulter", "Editer ce jeu de données", "Calendriers", "Dupliquer", "Contrôler", "Archiver","Supprimer ce jeu de données"]
            expect_action_link_hrefs(action).to match_array([
              [object],
              [:edit, object],
              referential_time_tables_path(object),
              new_workbench_referential_path(referential.workbench, from: object.id),
              select_compliance_control_set_referential_path(object),
              archive_referential_path(object),
              [object]
            ])
          end
        end

        context "on show" do
          let( :action){ :show }
          it 'has corresponding actions' do
            expect_action_link_elements(action).to match_array ["Courses", "Editer ce jeu de données", "Calendriers", "Dupliquer", "Contrôler", "Archiver", "Nettoyer", "Supprimer ce jeu de données"]
            expect_action_link_hrefs(action).to match_array([
              [:edit, object],
              referential_vehicle_journeys_path(object),
              referential_time_tables_path(object),
              new_workbench_referential_path(referential.workbench, from: object.id),
              select_compliance_control_set_referential_path(object),
              archive_referential_path(object),
              new_referential_clean_up_path(object),
              [object]
            ])
          end
        end

        context 'with a failed referential' do
          before{
            referential.ready = false
            referential.failed_at = Time.now
          }
          context "on index" do
            it 'has corresponding actions' do
              expect_action_link_elements(action).to match_array [
                "Consulter", "Supprimer ce jeu de données"
              ]
              expect_action_link_hrefs(action).to match_array([
                [object],
                [object]
              ])
            end
          end

          context "on show" do
            let( :action){ :show }
            it 'has corresponding actions' do
              expect_action_link_elements(action).to eq [
                "Supprimer ce jeu de données"
              ]
              expect_action_link_hrefs(action).to eq([
                [object]
              ])
            end
          end
        end
      end
    end

    context 'archived referential' do
      before {
        referential.ready = true
        referential.archived_at = 42.seconds.ago
      }
      context 'no rights' do
        it 'has only show and calendar actions' do
          expect_action_link_hrefs.to match_array([[object], referential_time_tables_path(object)])
        end
      end

      context 'all rights and different organisation' do
        let( :user ){ build_stubbed :allmighty_user }
        it 'has only default actions' do
          expect_action_link_elements.to match_array ["Consulter", "Calendriers", "Dupliquer"]
          expect_action_link_hrefs.to match_array([
            [object],
            referential_time_tables_path(object),
            new_workbench_referential_path(referential.workbench, from: object.id)
          ])
        end
      end

      context 'all rights and same organisation' do
        let( :user ){ build_stubbed :allmighty_user, organisation: referential.organisation }
        it 'has only default actions' do
          expect_action_link_elements.to match_array ["Consulter", "Calendriers", "Dupliquer", "Désarchiver", "Supprimer ce jeu de données"]
          expect_action_link_hrefs.to match_array([
            [object],
            referential_time_tables_path(object),
            new_workbench_referential_path(referential.workbench, from: object.id),
            unarchive_referential_path(object),
            [object]
          ])
        end
      end
    end

    context 'finalized offer' do
      before {
        referential.ready = true
        referential.failed_at = nil
        referential.referential_suite_id = 1
      }
      context 'no rights' do
        it 'has only show and calendar actions' do
          expect_action_link_hrefs.to match_array([[object], referential_time_tables_path(object)])
        end
      end

      context 'all rights and different organisation' do
        let( :user ){ build_stubbed :allmighty_user }
        it 'has only default actions' do
          expect_action_link_elements.to match_array ["Consulter", "Calendriers"]
          expect_action_link_hrefs.to match_array([
            [object],
            referential_time_tables_path(object),
          ])
        end
      end

      context 'all rights and same organisation' do
        let( :user ){ build_stubbed :allmighty_user, organisation: referential.organisation }
        it 'has only default actions' do
          expect_action_link_elements.to match_array ["Consulter", "Calendriers", "Contrôler"]
          expect_action_link_hrefs.to match_array([
            [object],
            referential_time_tables_path(object),
            select_compliance_control_set_referential_path(object)
          ])
        end
      end
    end
  end
end
