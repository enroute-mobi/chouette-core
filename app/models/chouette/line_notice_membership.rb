# frozen_string_literal: true

module Chouette
  class LineNoticeMembership < Chouette::ActiveRecord
    self.table_name = 'line_notices_lines'

    belongs_to :line, required: true, inverse_of: :line_notice_memberships
    belongs_to :line_notice, required: true, inverse_of: :line_notice_memberships

    validates :line_notice_id, uniqueness: { scope: %i[line_id] }
  end
end
