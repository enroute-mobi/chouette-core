# frozen_string_literal: true

module Query
  class User < Base
    def text(value)
      change_scope(if: value.present?) do |scope|
        table = scope.arel_table

        name = table[:name].matches("%#{value}%")
        email = table[:email].matches("%#{value}%")

        scope.where(name.or(email))
      end
    end

    def profile(value)
      where(value, :in, :profile)
    end

    def state(value) # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
      change_scope(if: value_present?(value)) do |scope|
        state_requests = value.map do |state|
          case state
          when 'blocked'
            scope.where.not(locked_at: nil)
          when 'confirmed'
            scope.where.not(confirmed_at: nil).where(locked_at: nil).and(
              scope.where(invitation_sent_at: nil).or(scope.where.not(invitation_accepted_at: nil))
            )
          when 'invited'
            scope.where.not(invitation_sent_at: nil).where(invitation_accepted_at: nil, locked_at: nil)
          when 'pending'
            scope.where(invitation_sent_at: nil, confirmed_at: nil, locked_at: nil)
          else
            scope.none
          end
        end

        state_requests.inject(scope.none) do |request, state_request|
          request.or(state_request)
        end
      end
    end
  end
end
