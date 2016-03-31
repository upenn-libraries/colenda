class MetadataBuildersController < ApplicationController

  before_action :set_metadata_builder, only: [:show, :edit, :update]
  before_filter :merge_mappings, :only => [:create, :update]

  def show
  end

  def new
    @metadata_builder = MetadataBuilder.new
  end

  def edit
  end

  def update
    @error_message = @metadata_builder.verify_xml_tags(params[:metadata_builder][:field_mappings]) if params[:metadata_builder][:field_mappings].present?
    if @metadata_builder.update(metadata_builder_params)
      @metadata_builder.generate_parent_child_xml if metadata_builder_params["nested_relationships"].present?
      flash[:success] = "Metadata Builder successfully updated"
      redirect_to "/admin_repo/repo/#{@metadata_builder.id}/map_metadata"
    else
      flash[:error] = @error_message
      redirect_to "/admin_repo/repo/#{@metadata_builder.id}/map_metadata"
    end
  end

  private

  def set_metadata_builder
    @metadata_builder = MetadataBuilder.find(params[:id])
  end

  def metadata_builder_params
    params.require(:metadata_builder).permit(:parent_repo, :source, :source_mappings, :field_mappings, :nested_relationships => [])
  end

  def merge_mappings
    params[:metadata_builder][:field_mappings] = params[:metadata_builder][:field_mappings].to_s if params[:metadata_builder][:field_mappings].present?
  end

end
