module Utils
  module Derivatives
    module Access
      extend self
      def generate_copy(file, destination)
        Utils::Derivatives.generate_copy(file, destination, :type => 'access')
      end
    end
  end
end
