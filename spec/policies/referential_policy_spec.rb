# coding: utf-8
RSpec.describe ReferentialPolicy, type: :pundit_policy do

  #
  # Collection Based Permissions differ from standard as there is no referential yet
  # --------------------------------------------------------------------------------
  context "on a ready referential" do
    let( :record ){ referential }
    permissions :create? do
      it 'permissions present → allowed' do
        add_permissions('referentials.create', to_user: user)
        expect_it.to permit(user_context, record)
      end
      it 'permissions absent → forbidden' do
        expect_it.not_to permit(user_context, record)
      end
    end

    permissions :new? do
      it 'permissions present → allowed' do
        add_permissions('referentials.create', to_user: user)
        expect_it.to permit(user_context, record)
      end
      it 'permissions absent → forbidden' do
        expect_it.not_to permit(user_context, record)
      end
    end

    #
    # Standard Destructive Action Permissions
    # ---------------------------------------

    permissions :destroy? do
      it_behaves_like 'permitted policy and same organisation', 'referentials.destroy', archived_and_finalised: false
    end
    permissions :edit? do
      it_behaves_like 'permitted policy and same organisation', 'referentials.update', archived_and_finalised: true
    end
    permissions :update? do
      it_behaves_like 'permitted policy and same organisation', 'referentials.update', archived_and_finalised: true
    end

    #
    # Custom Permissions
    # ------------------

    # permissions :clone? do
    #   it_behaves_like 'permitted policy', 'referentials.create', archived_and_finalised: true
    # end
    permissions :destroy? do
      context 'permission present →' do
        before do
          add_permissions('referentials.destroy', to_user: user)
        end
        context 'same organisation →' do
          before do
            user.organisation_id = referential.organisation_id
          end
          it "allows a user with the same organisation" do
            expect_it.to permit(user_context, record)
          end

          describe "archived" do
            let( :record ){ build_stubbed :referential, archived_at: 2.minutes.ago, ready: true  }
            it 'does not remove permission for archived referentials' do
              expect_it.to permit(user_context, record)
            end
          end

          describe "pending" do
            let( :record ){ build_stubbed :referential, ready: false  }
            it 'does remove permission for pending referentials' do
              expect_it.not_to permit(user_context, record)
            end
          end

          describe "in a referential suite" do
            let( :record ){ build_stubbed :referential, ready: true, referential_suite: create(:referential_suite)  }
            it 'does remove permission for pending referentials' do
              expect_it.not_to permit(user_context, record)
            end
          end

          describe "merged" do
            let( :record ){ build_stubbed :referential, ready: true, merged_at: 2.minutes.ago  }
            it 'does remove permission for pending referentials' do
              expect_it.not_to permit(user_context, record)
            end
          end

          describe "in error" do
            let( :record ){ build_stubbed :referential, failed_at: 2.minutes.ago, ready: false  }
            it 'does not remove permission for failed referentials' do
              expect_it.to permit(user_context, record)
            end
          end
        end
      end
    end

    permissions :archive? do
      context 'permission present →' do
        before do
          add_permissions('referentials.update', to_user: user)
        end

        context 'same organisation →' do
          before do
            user.organisation_id = referential.organisation_id
          end
          it "allows a user with the same organisation" do
            expect_it.to permit(user_context, record)
          end
          describe "archived" do
            let( :record ){ build_stubbed :referential, archived_at: 2.minutes.ago, ready: true  }
            it 'does remove permission for archived referentials' do
              expect_it.not_to permit(user_context, record)
            end
          end
        end

        context 'different organisations →' do
          it "forbids a user with a different organisation" do
            expect_it.not_to permit(user_context, record)
          end

          describe "archived" do
            let( :record ){ build_stubbed :referential, archived_at: 2.minutes.ago, ready: true  }
            it 'forbids for archived referentials' do
              expect_it.not_to permit(user_context, record)
            end
          end

        end
      end

      context 'permission absent →' do
        context 'same organisation →' do
          before do
            user.organisation_id = referential.organisation_id
          end
          it "forbids a user with the same organisation" do
            expect_it.not_to permit(user_context, record)
          end
          describe "archived" do
            let( :record ){ build_stubbed :referential, archived_at: 2.minutes.ago, ready: true  }
            it 'forbids for archived referentials' do
              expect_it.not_to permit(user_context, record)
            end
          end
        end
      end
    end

    permissions :unarchive? do

      context 'permission present →' do
        before do
          add_permissions('referentials.update', to_user: user)
        end

        context 'same organisation →' do
          before do
            user.organisation_id = referential.organisation_id
          end
          it "forbids a user with the same organisation" do
            expect_it.not_to permit(user_context, record)
          end
          describe "archived" do
            let( :record ){ build_stubbed :referential, archived_at: 2.minutes.ago, ready: true  }
            it 'adds permission for archived referentials' do
              expect_it.to permit(user_context, record)
            end
          end
        end

        context 'different organisations →' do
          it "forbids a user with a different organisation" do
            expect_it.not_to permit(user_context, record)
          end

          describe "archived" do
            let( :record ){ build_stubbed :referential, archived_at: 2.minutes.ago, ready: true  }
            it 'still forbids for archived referentials' do
              expect_it.not_to permit(user_context, record)
            end
          end

        end
      end

      context 'permission absent →' do
        context 'same organisation →' do
          before do
            user.organisation_id = referential.organisation_id
          end
          it "forbids a user with a different rganisation" do
            expect_it.not_to permit(user_context, record)
          end
          describe "archived" do
            let( :record ){ build_stubbed :referential, archived_at: 2.minutes.ago, ready: true  }
            it 'still forbids for archived referentials' do
              expect_it.not_to permit(user_context, record)
            end
          end
        end
      end
    end
  end
end
