require 'git'

module Utils
  module VersionControl
    class GitAnnex

      attr_accessor :repo, :remote_repo_path, :working_repo_path

      def initialize(repo)
        @repo = repo
        @remote_repo_path = "#{Utils.config.assets_path}/#{@repo.directory}"
        @working_repo_path = "/Users/katherly/Documents/working_dirs/#{@remote_repo_path}".gsub("//", "/")
      end

      def initialize_bare_remote
        `git init --bare #{@remote_repo_path}`
        Dir.chdir(@remote_repo_path)
        `git annex init origin`
      end

      def clone
        Git.clone(@remote_repo_path, @working_repo_path)
      end

      def checkout
      end

      def commit_and_push(commit_message)
        working_repo = Git.open(@working_repo_path)
        working_repo.add(:all => true)
        working_repo.commit(commit_message)
      end

      def remove_working_directory
        FileUtils.rm_rf(@working_repo_path) if File.directory?(@working_repo_path)
        #TODO: Add logging
      end

      def commit_and_remove_working_directory(commit_message)
        commit_and_push(commit_message)
        remove_working_directory
      end

    end
  end
end
