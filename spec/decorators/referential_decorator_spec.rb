# frozen_string_literal: true

RSpec.describe ReferentialDecorator, type: %i[helper decorator] do
  let(:policy_context_class) { Policy::Context::Workbench }
  let(:current_workbench) { build_stubbed :workbench }
  let(:referential_workbench) { build_stubbed :workbench }
  let(:current_referential) { build_stubbed :referential, workbench: referential_workbench }
  let(:context) { { workbench: current_workbench } }
  let(:object) { current_referential }

  describe 'delegation' do
    it 'delegates all' do
      %i[xx xxx anything save!].each do |method|
        expect(object).to receive(method)
      end
      # Almost as powerful as Quicktest :P
      %i[xx xxx anything save!].each do |method|
        subject.send method
      end
    end
  end

  describe 'action links for' do
    context 'unarchived referential' do
      context 'no rights' do
        it 'has only show and Calendar actions' do
          expect_action_link_hrefs.to match_array(
            [[current_workbench, object], workbench_referential_time_tables_path(context[:workbench], object)]
          )
        end
      end

      context 'all rights and different organisation' do
        let(:current_user) { build_stubbed :allmighty_user }

        it 'has only default actions' do
          expect_action_link_elements.to match_array %w[Consulter Calendriers Dupliquer]
          expect_action_link_hrefs.to match_array([
                                                    [current_workbench, object],
                                                    workbench_referential_time_tables_path(current_workbench, object),
                                                    new_workbench_referential_path(current_workbench,
                                                                                   from: object.id)
                                                  ])
        end
      end
      context 'all rights and same organisation' do
        let(:current_user) { build_stubbed :allmighty_user }
        let(:current_workbench) { referential_workbench }
        let(:action) { :index }

        context 'on index' do
          it 'has corresponding actions' do
            expect_action_link_elements(action).to match_array ['Consulter', 'Editer ce jeu de données', 'Calendriers',
                                                                'Dupliquer', 'Contrôler', 'Archiver', 'Supprimer ce jeu de données']
            expect_action_link_hrefs(action).to match_array([
                                                              [current_workbench, object],
                                                              [:edit, current_workbench, object],
                                                              workbench_referential_time_tables_path(
                                                                current_workbench,
                                                                object
                                                              ),
                                                              new_workbench_referential_path(current_workbench,
                                                                                             from: object.id),
                                                              new_workbench_control_list_run_path(
                                                                current_workbench, referential_id: object.id
                                                              ),
                                                              archive_workbench_referential_path(
                                                                current_workbench,
                                                                object
                                                              ),
                                                              [current_workbench, object]
                                                            ])
          end
        end

        context 'on show' do
          let(:action) { :show }
          it 'has corresponding actions' do
            expect_action_link_elements(action).to match_array [
              'Courses', 'Editer ce jeu de données', 'Calendriers', "Ensembles d'installations de services",
              'Dupliquer', 'Contrôler', 'Archiver', 'Nettoyer', 'Supprimer ce jeu de données']
            expect_action_link_hrefs(action).to match_array([
                                                              [:edit, current_workbench, object],
                                                              workbench_referential_vehicle_journeys_path(
                                                                current_workbench,
                                                                object
                                                              ),
                                                              workbench_referential_time_tables_path(
                                                                current_workbench,
                                                                object
                                                              ),
                                                              workbench_referential_service_facility_sets_path(
                                                                current_workbench,
                                                                object
                                                              ),
                                                              new_workbench_referential_path(current_workbench,
                                                                                             from: object.id),
                                                              new_workbench_control_list_run_path(
                                                                current_workbench, referential_id: object.id
                                                              ),
                                                              archive_workbench_referential_path(
                                                                current_workbench,
                                                                object
                                                              ),
                                                              new_workbench_referential_clean_up_path(
                                                                current_workbench,
                                                                object
                                                              ),
                                                              [current_workbench, object]
                                                            ])
          end
        end

        context 'with a failed referential' do
          before do
            object.ready = false
            object.failed_at = Time.zone.now
          end
          context 'on index' do
            it 'has corresponding actions' do
              expect_action_link_elements(action).to match_array [
                'Consulter', 'Supprimer ce jeu de données'
              ]
              expect_action_link_hrefs(action).to match_array([
                                                                [current_workbench, object],
                                                                [current_workbench, object]
                                                              ])
            end
          end

          context 'on show' do
            let(:action) { :show }
            it 'has corresponding actions' do
              expect_action_link_elements(action).to eq [
                'Supprimer ce jeu de données'
              ]
              expect_action_link_hrefs(action).to eq([
                                                       [current_workbench, object]
                                                     ])
            end
          end
        end
      end
    end

    context 'archived referential' do
      before do
        object.ready = true
        object.archived_at = 42.seconds.ago
      end
      context 'no rights' do
        it 'has only show and calendar actions' do
          expect_action_link_hrefs.to match_array(
            [[current_workbench, object], workbench_referential_time_tables_path(current_workbench, object)]
          )
        end
      end

      context 'all rights and different organisation' do
        let(:current_user) { build_stubbed :allmighty_user }
        it 'has only default actions' do
          expect_action_link_elements.to match_array %w[Consulter Calendriers Dupliquer]
          expect_action_link_hrefs.to match_array([
                                                    [current_workbench, object],
                                                    workbench_referential_time_tables_path(current_workbench, object),
                                                    new_workbench_referential_path(current_workbench,
                                                                                   from: object.id)
                                                  ])
        end
      end

      context 'all rights and same organisation' do
        let(:current_user) { build_stubbed :allmighty_user }
        let(:current_workbench) { referential_workbench }

        it 'has only default actions' do
          expect_action_link_elements.to match_array ['Consulter', 'Calendriers', 'Dupliquer', 'Désarchiver',
                                                      'Supprimer ce jeu de données']
          expect_action_link_hrefs.to match_array([
                                                    [current_workbench, object],
                                                    workbench_referential_time_tables_path(
                                                      current_workbench,
                                                      object
                                                    ),
                                                    new_workbench_referential_path(current_workbench,
                                                                                   from: object.id),
                                                    unarchive_workbench_referential_path(
                                                      current_workbench,
                                                      object
                                                    ),
                                                    [current_workbench, object]
                                                  ])
        end
      end
    end

    context 'finalized offer' do
      before do
        object.ready = true
        object.failed_at = nil
        object.referential_suite_id = 1
      end
      context 'no rights' do
        it 'has only show and calendar actions' do
          expect_action_link_hrefs.to match_array(
            [[current_workbench, object], workbench_referential_time_tables_path(current_workbench, object)]
          )
        end
      end

      context 'all rights and different organisation' do
        let(:current_user) { build_stubbed :allmighty_user }
        it 'has only default actions' do
          expect_action_link_elements.to match_array %w[Consulter Calendriers]
          expect_action_link_hrefs.to match_array([
                                                    [current_workbench, object],
                                                    workbench_referential_time_tables_path(current_workbench, object)
                                                  ])
        end
      end

      context 'all rights and same organisation' do
        let(:current_user) { build_stubbed :allmighty_user }
        let(:current_workbench) { referential_workbench }

        it 'has only default actions' do
          expect_action_link_elements.to match_array %w[Consulter Calendriers Contrôler]
          expect_action_link_hrefs.to match_array([
                                                    [current_workbench, object],
                                                    workbench_referential_time_tables_path(current_workbench, object),
                                                    new_workbench_control_list_run_path(current_workbench,
                                                                                        referential_id: object.id)
                                                  ])
        end
      end
    end
  end
end
