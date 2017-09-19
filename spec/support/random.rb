module Support
  module Random

    PRETTY_LARGE_INT = 1 << 30 

    def random_hex
      SecureRandom.hex
    end

    def random_int
      (random_number * PRETTY_LARGE_INT).to_i
    end

    def random_number
      SecureRandom.random_number
    end

    def random_string
      SecureRandom.urlsafe_base64
    end
  end
end

RSpec.configure do | c |
  c.include Support::Random
end
