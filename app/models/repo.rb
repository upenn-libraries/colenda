require 'git'

class Repo < ActiveRecord::Base

  validates :title, presence: true
  validates :directory, presence: true
  validates :metadata_subdirectory, presence: true
  validates :assets_subdirectory, presence: true
  validates :metadata_filename, presence: true
  validates :file_extensions, presence: true

  validates :title, multiple: false
  validates :directory, multiple: false

  serialize :metadata_sources

  include Filesystem

  def create_remote
    unless Dir.exists?("#{assets_path_prefix}/#{self.directory}")
      @full_directory_path = "#{assets_path_prefix}/#{self.directory}"
      build_and_populate_directories
      Git.init(@full_directory_path)
      Dir.chdir(@full_directory_path)
      `git annex init`
      return { :success => "Remote successfully created" }
    else
      return { :error => "Remote already exists" }
    end
  end

  def set_metadata_sources
    begin
      metadata_sources = Array.new
      Dir.glob("#{Utils.config.assets_path}/#{self.directory}/#{self.metadata_subdirectory}/*") do |file|
        metadata_sources << file
      end
      self.metadata_sources = metadata_sources
      self.save
    rescue
      raise "No metadata sources detected"
    end
  end

private
  def build_and_populate_directories
    admin_subdirectory = "admin"
    Dir.mkdir(@full_directory_path)
    Dir.mkdir("#{@full_directory_path}/#{self.metadata_subdirectory}")
    Dir.mkdir("#{@full_directory_path}/#{self.assets_subdirectory}")
    Dir.mkdir("#{@full_directory_path}/#{admin_subdirectory}")
    populate_admin_manifest("#{@full_directory_path}/#{admin_subdirectory}")
  end

  def populate_admin_manifest(full_admin_path)
    manifest_path = "#{full_admin_path}/manifest.txt"
    file_types = define_file_types
    metadata_line = "#{Utils.config.metadata_path_label}: #{self.metadata_subdirectory}/#{metadata_filename}"
    assets_line = "#{Utils.config.file_path_label}: #{self.assets_subdirectory}/#{file_types}"
    File.open(manifest_path, "w+") do |file|
      file.puts("#{metadata_line}\n#{assets_line}")
    end
  end

  def define_file_types
    ft = self.file_extensions.split(",")
    ft.map! { |f| ".#{f}"}
    aft = ft.join(',')
    aft = "*{#{aft}}"
    return aft
  end

end
