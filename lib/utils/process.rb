require 'fastimage'

module Utils
  module Process
    include Finder

    extend self

    def import(file, repo, working_path)
      Repo.update(repo.id, :ingested => false)
      repo.file_display_attributes = {}
      oid = repo.names.fedora
      status_type = :error
      repo.file_display_attributes = {}
      af_object = Finder.fedora_find(oid)
      delete_duplicate(af_object) if af_object.present?
      status_message = contains_blanks(file) ? I18n.t('colenda.utils.process.warnings.missing_identifier') : execute_curl(_build_command('import', :file => file))
      delete_members(oid)
      FileUtils.rm(file)
      file_extensions = { :images => %w[ tif tiff jpeg jpg ], :av => %w[ wav mp3 mp4 ], :downloadable => %w[ zip gz ], :pdf => %w[ pdf ] }
      attach_images(oid, repo, working_path) if repo.file_extensions.any? { |ext| file_extensions[:images].include?(ext) }

      file_extensions[:av].each do |ext|
        attach_av(repo, working_path, ext)
      end
      file_extensions[:downloadable].each do |ext|
        attach_downloadable(repo, working_path, ext)
      end
      file_extensions[:pdf].each do |ext|
        attach_pdf(repo, working_path, ext)
      end
      update_index(oid)

      repo.save!
      status_type = :success
      status_message = I18n.t('colenda.utils.process.success.ingest_complete')
      Repo.update(repo.id, :ingested => true, :queued => false)
      {status_type => status_message}
    end

    def delete_duplicate(af_object)
      object_id = af_object.id
      execute_curl(_build_command('delete', :object_uri => af_object.translate_id_to_uri.call(object_id)))
      execute_curl(_build_command('delete_tombstone', :object_uri => af_object.translate_id_to_uri.call(object_id)))
      clear_af_cache(object_id)
    end

    def delete_members(object_id)
      members_id = ActiveFedora::Base.id_to_uri("#{object_id}/members")
      execute_curl(_build_command('delete', :object_uri => members_id))
      execute_curl(_build_command('delete_tombstone', :object_uri => members_id))
    end

    def attach_images(oid, repo, working_path)
      af_object = Finder.fedora_find(oid)
      source_file =  "#{working_path}/#{repo.metadata_subdirectory}/#{repo.preservation_filename}"
      source_blob = File.read(source_file)
      reader = Nokogiri::XML(source_blob) do |config|
        config.options = Nokogiri::XML::ParseOptions::NOBLANKS
      end
      pages = reader.xpath('//pages/page')
      pages.each do |page|
        serialized_attributes = {}
        key_child = page.children.select{|x| x.name == 'file_name' }.last
        file_key = key_child.children.first.text
        k = repo.file_display_attributes.select{|k, v| v[:file_name].end_with?("#{file_key}.jpeg")}.first
        next if k.nil?
        file_print = read_storage_link(k.first, repo)
        page.children.each do |p|
          serialized_attributes[p.name] = p.children.first.present? ? p.children.first.text : ''
        end
        width, height = FastImage.size(file_print)
        dimensions = { 'width' => width, 'height' => height }
        serialized_attributes.merge!(dimensions)
        repo.images_to_render[file_print.to_s.html_safe] = serialized_attributes
      end
      af_object.save

      # Remove, increases ingest time exponentially for larger objects
      #`curl http://mdproc.library.upenn.edu:9292/records/#{repo.names.fedora}/create?format=iiif_presentation`

      repo.save!
    end

    def attach_av(repo, working_path, derivative)
      repo.file_extensions.each do |ext|
        Dir.glob("#{working_path}/#{repo.assets_subdirectory}/*.#{derivative}").each do |deriv|
          repo.file_display_attributes[File.basename(attachable_url(repo, working_path, deriv))] = { :content_type => derivative,
                                                                                                     :streaming_url => attachable_url(repo, working_path, deriv) }
        end
      end
      repo.save!
    end

    def attach_pdf(repo, working_path, derivative)
      repo.file_extensions.each do |ext|
        Dir.glob("#{working_path}/#{repo.assets_subdirectory}/*.#{derivative}").each do |deriv|
          repo.file_display_attributes[File.basename(attachable_url(repo, working_path, deriv))] = { :content_type => derivative,
                                                                                                     :pdf_url => attachable_url(repo, working_path, deriv) }
        end
      end
      repo.save!
    end

    def attach_downloadable(repo, working_path, derivative)
      repo.file_extensions.each do |ext|
        Dir.glob("#{working_path}/#{repo.assets_subdirectory}/*.#{derivative}").each do |deriv|
          repo.file_display_attributes[File.basename(attachable_url(repo, working_path, deriv))] = { :content_type => derivative,
                                                                                                     :download_url => attachable_url(repo, working_path, deriv),
                                                                                                     :filename => File.basename(deriv) }
        end
      end
      repo.save!
    end

    def generate_thumbnail(repo, working_path)
      unencrypted_thumbnail_path = "#{working_path}/#{repo.assets_subdirectory}/#{repo.thumbnail}"
      thumbnail_link = Dir.glob("#{working_path}/#{repo.derivatives_subdirectory}/**/**/**/thumbnail*").first
      if thumbnail_link.present?
        repo.version_control_agent.get({:location => thumbnail_link}, working_path)
        repo.version_control_agent.unlock({:content => thumbnail_link}, working_path)
      end
      derivatives_working_destination = "#{working_path}/#{repo.derivatives_subdirectory}"
      thumbnail_link = File.exist?(unencrypted_thumbnail_path) ? "#{working_path}/#{repo.derivatives_subdirectory}/#{Utils::Derivatives::Thumbnail.generate_copy(unencrypted_thumbnail_path, '', derivatives_working_destination)}" : ''
      repo.version_control_agent.add({ content: thumbnail_link, include_dotfiles: true }, working_path)
      url = attachable_url(repo, working_path, thumbnail_link)
      execute_curl(_build_command('file_attach', file: url, fid: repo.names.fedora, child_container: 'thumbnail'))
      repo.update(thumbnail_location: Addressable::URI.parse(url).path)
      repo.version_control_agent.lock(thumbnail_link, working_path)
      refresh_assets(working_path, repo)
    end

    def attachable_url(repo, working_path, file_path)
      relative_file_path = relative_path(working_path, file_path)
      repo.version_control_agent.add({content: relative_file_path}, working_path)
      repo.version_control_agent.copy({content: relative_file_path, to: Utils.config[:special_remote][:name]}, working_path)
      lookup_key = repo.version_control_agent.look_up_key(relative_file_path, working_path)
      read_storage_link(lookup_key, repo)
    end

    # TODO: Can remove this once file_path passed into attachable_url is relative.
    def relative_path(working_path, filepath)
      working_path = Pathname.new(working_path)
      filepath = Pathname.new(filepath)
      filepath.relative_path_from(working_path).to_s
    end

    def read_storage_link(key, repo)
      "#{Utils::Storage::Ceph.config.read_protocol}#{Utils::Storage::Ceph.config.read_host}/#{repo.names.bucket}/#{key}"
    end

    def refresh_assets(working_path, repo)
      repo.file_display_attributes = {}
      display_array = []
      entries = Dir.entries("#{working_path}/#{repo.derivatives_subdirectory}").reject { |f| File.directory?("#{working_path}/#{repo.derivatives_subdirectory}/#{f}") || f == '.keep' }
      entries.each do |file|
        file_path = "#{working_path}/#{repo.derivatives_subdirectory}/#{file}"
        width, height = FastImage.size(file_path)
        repo.file_display_attributes[File.basename(attachable_url(repo, working_path, file_path))] = {:file_name => "#{repo.derivatives_subdirectory}/#{File.basename(file_path)}",
                                                                                        :width => width,
                                                                                        :height => height}
      end
      unless repo.metadata_builder.metadata_source.where(:source_type => MetadataSource.structural_types).empty?
        repo.metadata_builder.get_structural_filenames.each do |filename|
          entry = repo.file_display_attributes.select{|key, hash| hash[:file_name].split('/').last == "#{filename}.jpeg"}
          raise I18n.t('colenda.utils.process.warnings.multiple_structural_files') if entry.length > 1
          display_array << entry.keys.first
        end
        repo.images_to_render['iiif'] = { 'reading_direction' => repo.metadata_builder.determine_reading_direction,
                                          'images' => display_array.map{ |s| "#{Display.config['iiif']['image_server']}/#{repo.names.bucket}%2F#{s}/info.json" }
        }
      end

      repo.save!
    end

    # Doesn't seem to be used.
    def jettison_originals(repo, working_path, commit_message)
      Dir.glob("#{working_path}/#{repo.assets_subdirectory}/*").each do |original|
        repo.version_control_agent.unlock({:content => original}, working_path)
        FileUtils.rm(original)
      end
      repo.version_control_agent.commit(commit_message, working_path)
    end

    def update_index(object_id)
      if check_persisted(object_id)
        object_and_descendants_action(object_id, 'update_index')
      end
    end

    def execute_curl(command)
      `#{command}`
    end

    protected

    def validate_file(file)
      begin
        f = MiniMagick::Image.open(file)
        return f, nil
      rescue => exception
        return nil, 'missing' if exception.inspect.downcase =~ /no such file/
        return nil, 'invalid' if exception.inspect.downcase =~ /minimagick::invalid/
        return nil, "#{exception.inspect.downcase}"
      end
    end

    def characterize_files(working_path, repo)
      target = "#{working_path}/#{repo.metadata_subdirectory}"
      jhove_xml = Utils::Artifacts::Metadata::Preservation::Jhove.new(working_path, target = target)
      jhove_xml.characterize
      jhove_xml
    end

    def contains_blanks(file)
      status = File.read(file) =~ /<sv:node sv:name="">/
      status.nil? ? false : true
    end

    def object_and_descendants_action(parent_id, action)
      uri = ActiveFedora::Base.id_to_uri(parent_id)
      refresh_ldp_contains(uri)
      descs = ActiveFedora::Base.descendant_uris(uri)
      descs.each do |desc|
        begin
          Finder.fedora_find(ActiveFedora::Base.uri_to_id(desc)).send(action)
        rescue
          next
        end
      end
    end

    def check_persisted(object_id)
      Ldp::Orm.new(Ldp::Resource::RdfSource.new(ActiveFedora.fedora.connection, ActiveFedora::Base.id_to_uri(object_id))).persisted?
    end

    def refresh_ldp_contains(container_uri)
      resource = Ldp::Resource::RdfSource.new(ActiveFedora.fedora.connection, container_uri)
      orm = Ldp::Orm.new(resource)
      orm.graph.delete
      orm.save
    end

    def clear_af_cache(object_id)
      uri = ActiveFedora::Base.id_to_uri(object_id)
      resource = Ldp::Resource::RdfSource.new(ActiveFedora.fedora.connection, uri)
      resource.client.clear_cache
    end

    private

    def _build_command(type, options = {})
      fedora_yml = "#{Rails.root}/config/fedora.yml"
      fedora_config = YAML.load(ERB.new(File.read(fedora_yml)).result)[Rails.env]
      fedora_user = fedora_config['user']
      fedora_password = fedora_config['password']
      fedora_link = "#{fedora_config['url']}#{fedora_config['base_path']}"
      child_container = options[:child_container]
      file = options[:file]
      fid = options[:fid]
      object_uri = options[:object_uri]
      case type
        when 'import'
          command = "curl -u #{fedora_user}:#{fedora_password} -X POST --data-binary \"@#{file}\" \"#{fedora_link}/fcr:import?format=jcr/xml\""
        when 'file_attach'
          fedora_full_path = "#{fedora_link}/#{fid}/#{child_container}"
          command = "curl -u #{fedora_user}:#{fedora_password}  -X PUT -H \"Content-Type: message/external-body; access-type=URL; URL=\\\"#{file}\\\"\" \"#{fedora_full_path}\""
        when 'delete'
          command = "curl -u #{fedora_user}:#{fedora_password} -X DELETE \"#{object_uri}\""
        when 'delete_tombstone'
          command = "curl -u #{fedora_user}:#{fedora_password} -X DELETE \"#{object_uri}/fcr:tombstone\""
        else
          raise I18n.t('colenda.utils.process.warnings.invalid_curl_command')
      end
      command
    end

  end
end
