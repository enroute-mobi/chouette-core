# frozen_string_literal: true

#
# Shortcut to expect change on subject invocation
#
# Usage:
#
#   it { is_expected_to change(...) }
#   it { is_expected_to_not change(...) }
#
# instead of
#
#   it { expect { subject }.to change(...) }
#   it { expect { subject }.to_not change(...) }
#
module IsExpectedTo
  def is_expected_to(*args)
    expect { subject }.to(*args)
  end

  def is_expected_to_not(*args)
    expect { subject }.to_not(*args)
  end
end

RSpec.configure do |config|
  config.include IsExpectedTo
end
