class Repo < ActiveRecord::Base

  has_one :metadata_builder, dependent: :destroy, :validate => false
  has_one :version_control_agent, dependent: :destroy, :validate => false

  before_validation :concatenate_git

  after_create :set_version_control_agent
  after_create :set_metadata_builder

  validates :title, presence: true
  validates :directory, presence: true
  validates :metadata_subdirectory, presence: true
  validates :assets_subdirectory, presence: true
  validates :metadata_filename, presence: true
  validates :file_extensions, presence: true

  validates :title, multiple: false
  validates :directory, multiple: false

  serialize :metadata_sources
  serialize :metadata_builder_id

  include Filesystem

  # def create_remote
  #   unless Dir.exists?("#{assets_path_prefix}/#{self.directory}")
  #     ga = Utils::VersionControl::GitAnnex.new(self)
  #     ga.initialize_bare_remote
  #     ga.clone
  #     build_and_populate_directories(ga.working_path)
  #     ga.commit_and_remove_working_directory("Building out directories")
  #     return { :success => "Remote successfully created" }
  #   else
  #     return { :error => "Remote already exists" }
  #   end
  # end

  def set_metadata_sources
    metadata_sources = Array.new
    self.version_control_agent.clone
    Dir.glob("#{self.version_control_agent.working_path}/#{self.metadata_subdirectory}/*") do |file|
      metadata_sources << file
    end
    self.metadata_sources = metadata_sources
    self.save
    status = Dir.glob("#{self.version_control_agent.working_path}/#{self.metadata_subdirectory}/*").empty? ? { :error => "No metadata sources detected." } : { :success => "Metadata sources detected -- see output below." }
    self.version_control_agent.delete_clone
    return status
  end

private
  def build_and_populate_directories(working_copy_path)
    #TODO: Config out
    admin_subdirectory = "admin"
    Dir.chdir("#{working_copy_path}")
    Dir.mkdir("#{self.metadata_subdirectory}") && FileUtils.touch("#{self.metadata_subdirectory}/.keep")
    Dir.mkdir("#{self.assets_subdirectory}") && FileUtils.touch("#{self.assets_subdirectory}/.keep")
    Dir.mkdir("#{admin_subdirectory}")
    populate_admin_manifest("#{admin_subdirectory}")
  end

  def populate_admin_manifest(admin_path)
    manifest_path = "#{admin_path}/manifest.txt"
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

  def set_version_control_agent
    self.version_control_agent = VersionControlAgent.new(:vc_type => "GitAnnex")
  end

  def set_metadata_builder
    self.metadata_builder = MetadataBuilder.new(:parent_repo => self.id)
    self.metadata_builder.save!
    self.save!
    self.metadata_builder.set_source
    self.metadata_builder.prep_for_mapping
    self.metadata_builder.save!
    self.save!
  end

  # TODO: Determine if this is really the best place to put this because we're dealing with Git bare repo best practices
  def concatenate_git
    self.directory.concat('.git') unless self.directory =~ /.git$/ || self.directory.nil?
  end


end
