# frozen_string_literal: true

RSpec.describe ActionDispatch::Session::CasRedisStore do
  subject(:cas_redis_store) { described_class.new(app) }

  let(:static_cas_redis_store) { described_class.new(nil) }

  let(:app) { double(:app) }
  let(:req) { double(:req) }
  let(:session_public_id) { double(:session_public_id) }
  let(:session_private_id) { double(:session_private_id) }
  let(:sid) { double(:sid, public_id: session_public_id, private_id: session_private_id) }

  let(:redis_client) { double(:redis_client) }
  let(:cas_ticket) { 'ST-669cf67a' }
  let(:session_data) { {} }

  before do
    allow(described_class).to receive(:store).and_return(static_cas_redis_store)
    allow(static_cas_redis_store).to receive(:with).and_yield(redis_client)

    allow(cas_redis_store).to receive(:with).and_yield(redis_client)
  end

  describe '.destroy_session_by_cas_ticket' do
    subject { described_class.destroy_session_by_cas_ticket(cas_ticket) }

    before { allow(redis_client).to receive(:get).with("rack_cas_ticket:#{cas_ticket}").and_return(session_private_id) }

    context 'when cas ticket is associated to a session id' do
      it 'deletes session data and cas ticket from redis' do
        expect(redis_client).to receive(:del).with(session_private_id)
        expect(redis_client).to receive(:del).with("rack_cas_ticket:#{cas_ticket}")
        subject
      end
    end

    context 'when cas ticket is unknown' do
      let(:session_private_id) { nil }

      it 'only deletes cas ticket from redis' do
        expect(redis_client).to receive(:del).with("rack_cas_ticket:#{cas_ticket}")
        subject
      end
    end
  end

  describe '#write_session' do
    subject { cas_redis_store.write_session(req, sid, session_data, options) }

    let(:options_hash) { double(:options_hash) }
    let(:options) { double(:options, to_hash: options_hash) }

    context 'when session data contains a cas ticket' do
      let(:session_data) { { 'cas' => { 'ticket' => cas_ticket } } }

      it 'writes session data and cas ticket in redis' do
        expect(redis_client).to receive(:set).with(session_private_id, session_data, options_hash)
        expect(redis_client).to receive(:set).with("rack_cas_ticket:#{cas_ticket}", session_private_id, options_hash)
        subject
      end
    end

    context 'when session data does not contain a cas ticket' do
      it 'only writes session data in redis' do
        expect(redis_client).to receive(:set).with(session_private_id, session_data, options_hash)
        subject
      end

      context 'but contains a cas key' do
        let(:session_data) { { 'cas' => {} } }

        it 'only writes session data in redis' do
          expect(redis_client).to receive(:set).with(session_private_id, session_data, options_hash)
          subject
        end
      end
    end
  end

  describe '#delete_session' do
    subject { cas_redis_store.delete_session(req, sid, {}) }

    before { allow(redis_client).to receive(:get).with(session_private_id).and_return(session_data) }

    context 'when session data contains a cas ticket' do
      let(:session_data) { { 'cas' => { 'ticket' => cas_ticket } } }

      it 'only deletes session private id and session public id' do
        expect(redis_client).to receive(:del).with(session_private_id)
        expect(redis_client).to receive(:del).with(session_public_id)
        expect(redis_client).to receive(:del).with("rack_cas_ticket:#{cas_ticket}")
        subject
      end
    end

    context 'when session data does not contain a cas ticket' do
      it 'only deletes session private id and session public id' do
        expect(redis_client).to receive(:del).with(session_private_id)
        expect(redis_client).to receive(:del).with(session_public_id)
        subject
      end

      context 'but contains a cas key' do
        let(:session_data) { { 'cas' => {} } }

        it 'only deletes session private id and session public id' do
          expect(redis_client).to receive(:del).with(session_private_id)
          expect(redis_client).to receive(:del).with(session_public_id)
          subject
        end
      end
    end

    context 'when no session corresponds to the session id' do
      let(:session_data) { nil }

      before { allow(redis_client).to receive(:get).with(session_public_id).and_return(nil) }

      it 'only deletes session private id and session public id' do
        expect(redis_client).to receive(:del).with(session_private_id)
        expect(redis_client).to receive(:del).with(session_public_id)
        subject
      end
    end
  end
end
