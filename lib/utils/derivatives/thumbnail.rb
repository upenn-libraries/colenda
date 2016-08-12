module Utils
  module Derivatives
    module Thumbnail
      extend self
      def generate_copy(file, destination)
        file_path = Utils::Derivatives.generate_copy(file, destination, :type => "thumbnail")
        return file_path
      end
    end
  end
end
