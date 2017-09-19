RSpec.describe ReferentialPolicy, type: :policy do

  let( :record ){ build_stubbed :referential }


  #
  # Collection Based Permissions differ from standard as there is no referential yet
  # --------------------------------------------------------------------------------

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
    it_behaves_like 'permitted policy and same organisation', 'referentials.destroy', archived: true
  end
  permissions :edit? do
    it_behaves_like 'permitted policy and same organisation', 'referentials.update', archived: true
  end
  permissions :update? do
    it_behaves_like 'permitted policy and same organisation', 'referentials.update', archived: true
  end

  #
  # Custom Permissions
  # ------------------

  permissions :clone? do
    it_behaves_like 'permitted policy', 'referentials.create', archived: true
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
          let( :record ){ build_stubbed :referential, archived_at: 2.minutes.ago  }
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
          let( :record ){ build_stubbed :referential, archived_at: 2.minutes.ago  }
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
          let( :record ){ build_stubbed :referential, archived_at: 2.minutes.ago  }
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
          let( :record ){ build_stubbed :referential, archived_at: 2.minutes.ago  }
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
          let( :record ){ build_stubbed :referential, archived_at: 2.minutes.ago  }
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
          let( :record ){ build_stubbed :referential, archived_at: 2.minutes.ago  }
          it 'still forbids for archived referentials' do
            expect_it.not_to permit(user_context, record)
          end
        end
      end
    end
  end
end
