
RSpec.shared_examples 'always allowed' do
  | permission, archived_and_finalised: false |
  context 'same organisation →' do
    before do
      user.organisation_id = referential.organisation_id
    end
    it "allows a user with the same organisation" do
      expect_it.to permit(user_context, record)
    end
    if archived_and_finalised
      it 'does not remove permission for archived referentials' do
        referential.archived_at = 42.seconds.ago
        expect_it.to permit(user_context, record)
      end

      it 'does not remove permission for finalised referentials' do
        finalise_referential
        expect_it.to permit(user_context, record)
      end
    end
  end

  context 'different organisations →' do
    before do
      add_permissions(permission, to_user: user)
    end
    it "allows a user with a different organisation" do
      expect_it.to permit(user_context, record)
    end
    if archived_and_finalised
      it 'does not remove permission for archived referentials' do
        referential.archived_at = 42.seconds.ago
        expect_it.to permit(user_context, record)
      end
      it 'does not remove permission for finalised referentials' do
        finalise_referential
        expect_it.to permit(user_context, record)
      end
    end
  end
end

RSpec.shared_examples 'always forbidden' do
  | permission, archived_and_finalised: false|
  context 'same organisation →' do
    before do
      user.organisation_id = referential.organisation_id
    end

    it "allows a user with the same organisation" do
      expect_it.not_to permit(user_context, record)
    end

    if archived_and_finalised
      it 'still no permission for archived referentials' do
        finalise_referential
        expect_it.not_to permit(user_context, record)
      end
    end
  end

  context 'different organisations →' do
    before do
      add_permissions(permission, to_user: user)
    end
    it "denies a user with a different organisation" do
      expect_it.not_to permit(user_context, record)
    end
    if archived_and_finalised
      it 'still no permission for archived referentials' do
        referential.archived_at = 42.seconds.ago
        expect_it.not_to permit(user_context, record)
      end

      it 'still no permission for finalised referentials' do
        finalise_referential
        expect_it.not_to permit(user_context, record)
      end
    end
  end
end

RSpec.shared_examples 'permitted policy and same workbench' do |permission|
  context 'permission absent → ' do
    it 'denies a user with a different workbench' do
      expect_it.not_to permit(user_context, record)
    end

    it 'and also a user with the same workbench' do
      record.workbench = user_context.context[:workbench]
      expect_it.not_to permit(user_context, record)
    end
  end

  context 'permission present → ' do
    before do
      add_permissions(permission, to_user: user)
    end

    it 'denies a user with a different workbench' do
      expect_it.not_to permit(user_context, record)
    end

    it 'but allows it for a user with the same workbench' do
      record.workbench = user_context.context[:workbench]
      expect_it.to permit(user_context, record)
    end
  end
end

RSpec.shared_examples 'permitted policy and same organisation' do
  | permission, archived_and_finalised: false |

  context 'permission absent → ' do
    it "denies a user with a different organisation" do
      expect_it.not_to permit(user_context, record)
    end
    it 'and also a user with the same organisation' do
      user.organisation_id = referential.organisation_id
      expect_it.not_to permit(user_context, record)
    end
  end

  context 'permission present → '  do
    before do
      add_permissions(permission, to_user: user)
    end

    it 'denies a user with a different organisation' do
      expect_it.not_to permit(user_context, record)
    end

    it 'but allows it for a user with the same organisation' do
      user.organisation_id = referential.organisation_id
      expect_it.to permit(user_context, record)
    end

    if archived_and_finalised
      it 'removes the permission for archived referentials' do
        user.organisation_id = referential.organisation_id
        referential.archived_at = 42.seconds.ago
        referential.ready = true
        expect_it.not_to permit(user_context, record)
      end

      it 'removes the permission for finalised referentials' do
        user.organisation_id = referential.organisation_id
        finalise_referential
        expect_it.not_to permit(user_context, record)
      end
    end
  end
end

RSpec.shared_examples 'permitted policy' do
  | permission, archived_and_finalised: false|

  context 'permission absent → ' do
    it "denies user" do
      expect_it.not_to permit(user_context, record)
    end
  end

  context 'permission present → '  do
    before do
      add_permissions(permission, to_user: user)
    end

    it 'allows user' do
      expect_it.to permit(user_context, record)
    end

    if archived_and_finalised
      it 'removes the permission for archived referentials' do
        user.organisation_id = referential.organisation_id
        referential.archived_at = 42.seconds.ago
        expect_it.not_to permit(user_context, record)
      end
      it 'removes the permission for finalised referentials' do
        user.organisation_id = referential.organisation_id
        finalise_referential
        expect_it.not_to permit(user_context, record)
      end
    end
  end
end

RSpec.shared_examples 'permitted policy but unmet condition' do
  | permission|

  context 'permission absent → ' do
    it "denies user" do
      expect_it.not_to permit(user_context, record)
    end
  end

  context 'permission present → '  do
    before do
      add_permissions(permission, to_user: user)
    end

    it 'denies user' do
      expect_it.not_to permit(user_context, record)
    end
  end
end

RSpec.shared_examples 'permitted policy outside referential' do
  | permission |

  context 'permission absent → ' do
    it "denies user" do
      expect_it.not_to permit(user_context, record)
    end
  end

  context 'permission present → '  do
    before do
      add_permissions(permission, to_user: user)
    end

    it 'allows user' do
      expect_it.to permit(user_context, record)
    end
  end
end
