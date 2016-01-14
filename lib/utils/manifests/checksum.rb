require 'digest'
module Utils
  module Manifests
    class Checksum

      attr_accessor :hash_type, :content

      def initialize(hash_type)
        begin
          @hash_type = hash_type
          @digest = set_digest(@hash_type)
          @checksums_hash = Hash.new
        rescue
          raise $!, "Checksumming agent not created due to the following error(s): #{$!}", $!.backtrace
        end
      end

      def calculate(file_list)
        file_list.each do |file_to_check|
          checksum = @digest.file file_to_check
          @checksums_hash[file_to_check] = checksum.hexdigest
        end
        @content = format_content
      end

      private
        def set_digest(hash_type)
          case hash_type.downcase
            when "sha256"
              digest = Digest::SHA256
            when "sha1"
              digest = Digest::SHA1
            when "sha2"
              digest = Digest::SHA2
            when "md5"
              digest = Digest::MD5
            when "rmd160"
              digest = Digest::RMD160
            else
              raise "#{@hash_type} is not a valid hash type."
          end
          return digest
        end

        def get_file_list

        end

        def format_content
          formatted_checksums_hash = ""
          @checksums_hash.each do |row|
             formatted = row.flatten.join("\t")
             formatted_checksums_hash += formatted
          end
          return formatted_checksums_hash
        end

    end
  end
end
