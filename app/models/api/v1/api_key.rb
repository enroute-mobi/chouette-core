module Api
  module V1
    class ApiKey < ::ActiveRecord::Base
      before_create :generate_access_token
      belongs_to :referential, :class_name => '::Referential'
      validates_presence_of :referential

      class << self
        def from(referential, name:)
          find_or_create_by!(name: name, referential: referential)
        end
        def model_name
          ActiveModel::Name.new  Api::V1, self.name.demodulize
        end
        def referential_from_token(token)
          array = token.split('-')
          return nil unless array.size==2
          ::Referential.find( array.first)
        end
      end

      def eql?(other)
        return false unless other.respond_to?( :token)
        other.token == self.token
      end


    private
      def generate_access_token
        begin
          self.token = "#{referential_id}-#{SecureRandom.hex}"
        end while self.class.exists?(:token => self.token)
      end
    end
  end
end

