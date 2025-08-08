# frozen_string_literal: true

RSpec.describe Query::User do
  subject(:query) { described_class.new(scope) }

  let(:scope) { context.organisation.users }

  describe '#text' do
    subject { query.text(value).scope }

    let(:context) do
      Chouette.create do
        user :match, name: 'name_match', email: 'email_match@match.ex'
        user :other, name: 'other', email: 'other@other.ex'
      end
    end

    context 'with empty string' do
      let(:value) { '' }

      it 'returns all users' do
        is_expected.to match_array(scope)
      end
    end

    context 'with name' do
      let(:value) { 'name_match' }

      it 'returns only matching user' do
        is_expected.to match_array([context.user(:match)])
      end

      context 'with only a part of name' do
        let(:value) { 'ame_mat' }

        it 'still returns matching user' do
          is_expected.to match_array([context.user(:match)])
        end
      end

      context 'with caps' do
        let(:value) { 'NAME_MATCH' }

        it 'still returns matching user' do
          is_expected.to match_array([context.user(:match)])
        end
      end
    end

    context 'with email' do
      let(:value) { 'email_match' }

      it 'returns only matching user' do
        is_expected.to match_array([context.user(:match)])
      end

      context 'with only a part of name' do
        let(:value) { 'mail_mat' }

        it 'still returns matching user' do
          is_expected.to match_array([context.user(:match)])
        end
      end

      context 'with caps' do
        let(:value) { 'EMAIL_MATCH' }

        it 'still returns matching user' do
          is_expected.to match_array([context.user(:match)])
        end
      end
    end
  end

  describe '#profile' do
    subject { query.profile(value).scope }

    let(:context) do
      Chouette.create do
        user :admin, profile: 'admin'
        user :editor, profile: 'editor'
        user :visitor, profile: 'visitor'
      end
    end

    context 'without value' do
      let(:value) { nil }

      it 'returns all users' do
        is_expected.to match_array(scope)
      end

      context 'as an array with an empty string' do
        let(:value) { [''] }

        it 'returns all users' do
          is_expected.to match_array(scope)
        end
      end
    end

    context 'with profiles' do
      let(:value) { %w[admin visitor] }

      it 'returns only matching users' do
        is_expected.to match_array([context.user(:admin), context.user(:visitor)])
      end
    end
  end

  describe '#state' do
    subject { query.state(value).scope }

    let(:context) do
      Chouette.create do
        now = Time.zone.now

        user :pending, confirmed_at: nil, invitation_sent_at: nil, locked_at: nil
        user :invited, confirmed_at: now, invitation_sent_at: now, invitation_accepted_at: nil, locked_at: nil
        user :confirmed, confirmed_at: now, invitation_sent_at: now, invitation_accepted_at: now, locked_at: nil
        user :blocked, confirmed_at: nil, invitation_sent_at: nil, locked_at: now
      end
    end

    context 'without value' do
      let(:value) { nil }

      it 'returns all users' do
        is_expected.to match_array(scope)
      end

      context 'as an array with an empty string' do
        let(:value) { [''] }

        it 'returns all users' do
          is_expected.to match_array(scope)
        end
      end
    end

    %i[
      pending
      invited
      confirmed
      blocked
    ].each do |state|
      context "with state \"#{state}\"" do
        let(:value) { [state.to_s] }

        it "returns only #{state} users" do
          is_expected.to match_array([context.user(state)])
        end
      end
    end

    context 'with unknown state' do
      let(:value) { %w[unknown] }

      it 'returns an empty array' do
        is_expected.to be_empty
      end
    end

    context 'with many state' do
      let(:value) { %w[pending confirmed] }

      it 'returns only matching users' do
        is_expected.to match_array([context.user(:pending), context.user(:confirmed)])
      end
    end

    context 'with all state' do
      let(:value) { %w[pending invited confirmed blocked unknown] }

      it 'returns all users' do
        is_expected.to match_array(scope)
      end
    end
  end
end
