module Support
  module Random

    PRETTY_LARGE_INT = 1 << 30 

    def random_hex
      SecureRandom.hex
    end

    def random_element from
      from[random_int(from.size)]
    end
    
    def random_elements( from, count: )
      (1..count).map{ |_| random_element from }
    end

    def distinct_random_elements( from, count: )
      f = from.dup
      (1..count).map { |_| f.delete_at( random_int(f.size) ) }
    end

    def random_int max_plus_one=PRETTY_LARGE_INT
      (random_number * max_plus_one).to_i
    end

    def random_number
      SecureRandom.random_number
    end

    def random_string
      SecureRandom.urlsafe_base64
    end

    def very_random(veryness=3, joiner: '-')
      raise ArgumentError, 'not very random' unless veryness > 1
      veryness.times.map{ SecureRandom.uuid }.join(joiner)
    end

  end
end

RSpec.configure do | c |
  c.include Support::Random
end
