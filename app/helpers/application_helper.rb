module ApplicationHelper

  include RailsAdmin::ApplicationHelper

  def render_image_list
    repo = Repo.where(:unique_identifier => @document.id.reverse_fedorafy).first
    return '' unless repo.present? && repo.images_to_render.present?
    images_list = repo.images_to_render['iiif'].present? ? repo.images_to_render['iiif']['images'] : legacy_image_list(repo)
    return content_tag(:div, '', id: 'pages', data: images_list.to_json ) + render_openseadragon(repo)
  end

  def render_featured_list
    items = ''
    Dir.glob("#{Rails.root}/public/assets/featured/manifests/*.yml").each do |manifest|
      data = YAML.load(File.read(manifest))
      text_link = link_to(data[:title], data[:link])
      image = image_tag("/assets/featured/#{data[:filename]}", :alt => data[:title])
      image_link =  link_to(image.html_safe, data[:link])
      span = content_tag(:span, text_link)
      link_div = content_tag(:div, span, {:class => 'bx-caption'})
      item_contents = link_div + image_link
      featured_item = content_tag(:li, item_contents, {:title => data[:title]})
      items << featured_item
    end
    return items.html_safe
  end

  def resolve_reading_direction(repo)
    reading_direction = repo.images_to_render['iiif'].present? ? repo.images_to_render['iiif']['reading_direction'] : legacy_reading_direction(repo)
    return 'ltr' unless reading_direction.present?
    return 'ltr' if %w[left-to-right ltr].include?(reading_direction)
  end

  def render_ableplayer
    repo = Repo.where(:unique_identifier => @document.id.reverse_fedorafy).first
    partials = ''
    return '' unless repo.present?
    repo.file_display_attributes.each do |key, value|
       partials += render :partial => 'av_display/audio', :locals => {:streaming_id => key, :streaming_url => value[:streaming_url]} if value[:content_type] == 'mp3'
       partials += render :partial => 'av_display/video', :locals => {:streaming_id => key, :streaming_url => value[:streaming_url]} if value[:content_type] == 'mp4'
    end
    return partials.html_safe
  end

  def render_warc
    repo = Repo.where(:unique_identifier => @document.id.reverse_fedorafy).first
    partials = ''
    return '' unless repo.present?
    repo.file_display_attributes.each do |key, value|
      partials += render :partial => 'other_display/warc', :locals => {:download_url => value[:download_url].gsub("#{Utils::Storage::Ceph.config.protocol}#{Utils::Storage::Ceph.config.host}",''), :filename => value[:filename]} if value[:content_type] == 'gz'
    end
    return partials.html_safe
  end

  def render_pdf
    repo = Repo.where(:unique_identifier => @document.id.reverse_fedorafy).first
    partials = ''
    return '' unless repo.present?
    repo.file_display_attributes.each do |key, value|
      partials += render :partial => 'other_display/pdf', :locals => {:pdf_url => value[:pdf_url]} if value[:content_type] == 'pdf'
    end
    return partials.html_safe
  end

  def render_uv
    repo = Repo.where(:unique_identifier => @document.id.reverse_fedorafy).first
    partials = ''
    partials += render :partial => 'other_display/uv'
    return partials.html_safe if repo.images_to_render.present?
  end

  def render_iiif_manifest_link
    return repo.images_to_render.present? ? link_to("IIIF presentation manifest", "#{ENV['UV_URL']}/#{@document.id}/manifest") : ''
  end

  def render_catalog_link
    repo = Repo.where(:unique_identifier => @document.id.reverse_fedorafy).first
    return repo.metadata_builder.metadata_source.first.original_mappings["bibid"].present? ? link_to("Franklin record", "https://franklin.library.upenn.edu/catalog/FRANKLIN_#{repo.metadata_builder.metadata_source.first.original_mappings["bibid"]}") : ''
  end

  def additional_resources
    repo = Repo.where(:unique_identifier => @document.id.reverse_fedorafy).first

    return true if repo.metadata_builder.metadata_source.first.original_mappings["bibid"].present? ||
        repo.images_to_render.present?
  end

  def universal_viewer_path(identifier)
    "/uv/uv#?manifest=uv/uv#?manifest=#{ENV['UV_URL']}/#{identifier}/manifest&config=/uv/uv-config.json"
  end

    def render_reviewed_queue
    a = ''
    ids = Repo.where('queued' => 'ingest').pluck(:id, :human_readable_name)
    a = 'Nothing approved waiting for batching' if ids.length == 0
    ids.each do |id|
      a << content_tag(:li,link_to(id[1], "#{Rails.application.routes.url_helpers.rails_admin_url(:only_path => true)}/repo/#{id[0]}/ingest"))
    end
    return content_tag(:ul, a.html_safe)
  end

  def render_fedora_queue
    a = ''
    ids = Repo.where('queued' => 'fedora').pluck(:id, :human_readable_name)
    a = 'Nothing in the queue' if ids.length == 0
    ids.each do |id|
      a << content_tag(:li,link_to(id[1], "#{Rails.application.routes.url_helpers.rails_admin_url(:only_path => true)}/repo/#{id[0]}/ingest"))
    end
    return content_tag(:ul, a.html_safe)
  end

  def flash_class(level)
    case level
      when :notice then 'alert alert-info'
      when :success then 'alert alert-success'
      when :error then 'alert alert-error'
      when :alert then 'alert alert-error'
      else 'alert alert-info'
    end
  end

  def menu_for(parent, abstract_model = nil, object = nil, only_icon = false)
    actions = actions(parent, abstract_model, object).select { |a| a.http_methods.include?(:get) }
    actions.collect do |action|
      wording = wording_for(:menu, action)
      %(
          <li title="#{wording if only_icon}" rel="#{'tooltip' if only_icon}" class="icon #{action.key}_#{parent}_link #{'active' if current_action?(action)}">
            <a class="#{action.pjax? ? 'pjax' : ''}" href="#{rails_admin.url_for(action: action.action_name, controller: 'rails_admin/main', model_name: abstract_model.try(:to_param), id: (object.try(:persisted?) && object.try(:id) || nil))}">
              <i class="#{action.link_icon}"></i>
              <div class="wording">#{wording}</div>
            </a>
          </li>
        )
    end.join.html_safe
  end

  def public_fedora_path(path)
    # TODO: Turn env var into config option?
    if ENV['PUBLIC_FEDORA_URL'].present?
      fedora_yml = "#{Rails.root}/config/fedora.yml"
      fedora_config = YAML.load(ERB.new(File.read(fedora_yml)).result)[Rails.env]
      fedora_link = "#{fedora_config['url']}#{fedora_config['base_path']}"
      return path.gsub(fedora_link, ENV['PUBLIC_FEDORA_URL'])
    else
      return path
    end
  end

  def legacy_image_list(repo)
    display_array = []
    repo.metadata_builder.get_structural_filenames.each do |filename|
      entry = repo.file_display_attributes.select{|key, hash| hash[:file_name].split('/').last == "#{filename}.jpeg"}
      display_array << entry.keys.first
    end
    return display_array.map{|k|"#{Display.config['iiif']['image_server']}#{repo.names.bucket}%2F#{k}/info.json"}

  end

  def legacy_reading_direction(repo)
    return repo.images_to_render.first.present? ? repo.images_to_render.first[1]['reading_direction'].first : 'left-to-right'
  end

end
