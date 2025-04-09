# frozen_string_literal: true

require 'action_dispatch/middleware/session/redis_store'

# NOTE: This code must be up to date with:
#   - Rack::Session::Redis (gem redis-rack)
#   - ActiveDispatch::Session::RedisStore (gem redis-actionpack)
# Any update in one of these gems must be analyzed to see if we need to change this code.

module ActionDispatch
  module Session
    class CasRedisStore < RedisStore
      class << self
        def destroy_session_by_cas_ticket(cas_ticket)
          cas_ticket_redis_id = store.cas_ticket_redis_id(cas_ticket)

          store.with do |c|
            session_id = c.get(cas_ticket_redis_id)

            c.del(session_id) if session_id
            c.del(cas_ticket_redis_id)
          end
        end

        private

        def store
          @store ||= ::Rails.application.middleware.find { |m| m.klass.is_a?(Class) && m.klass <= self }.build(nil)
        end
      end

      # based on ActiveDispatch::Session::RedisStore#write_session
      def write_session(req, sid, new_session, options = {})
        cas_ticket = new_session['cas']['ticket'] if new_session['cas']

        with_lock(req, false) do
          with do |c|
            c.set(sid.private_id, new_session, options.to_hash)

            if cas_ticket
              # sid.private_id changes after the first request so we cannot use #setnx
              c.set("rack_cas_ticket:#{cas_ticket}", sid.private_id, options.to_hash)
            end
          end
          sid
        end
      end

      # based on ActiveDispatch::Session::RedisStore#delete_session
      def delete_session(req, sid, options)
        with_lock(req) do
          with do |c|
            session = get_session_with_fallback(sid)
            cas_ticket = session['cas']['ticket'] if session && session['cas']
            c.del(cas_ticket_redis_id(cas_ticket)) if cas_ticket

            c.del(sid.public_id)
            c.del(sid.private_id)
          end
          generate_sid unless options[:drop]
        end
      end

      def cas_ticket_redis_id(cas_ticket)
        "rack_cas_ticket:#{cas_ticket}"
      end
    end
  end
end
