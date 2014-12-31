class AssetsController < ApplicationController
  before_action :set_asset, only: [:show, :edit, :update, :destroy]

  respond_to :html

  def index
    if user_signed_in?
      @folders = current_user.folders.roots  
      @assets = current_user.assets.where("folder_id is NULL").order("uploaded_file_file_name desc")
      respond_with(@assets)
    end
  end

  def show
    respond_with(@asset)
  end

  def new
    @asset = current_user.assets.new
    respond_with(@asset)
  end

  def edit
  end

  def create    
    @asset = current_user.assets.create(asset_params)
    # @asset.save
    if @asset.save
      render json: { message: "success", fileID: @asset.id }
    else
      debugger
      #  you need to send an error header, otherwise Dropzone
      #  will not interpret the response as an error:
      render json: { error: @upload.errors.full_messages.join(',')}, :status => 400
    end
    # redirect_to root_url
  end

  def update
    @asset.update(asset_params)
    respond_with(@asset)
  end

  def destroy
    @asset.destroy
    redirect_to root_url
  end

  def get 
    #first find the asset within own assets 
    # asset = current_user.assets.find_by_id(params[:id]).present? ? current_user.assets.find_by_id(params[:id]) : []
    asset = current_user.assets.find_by_id(params[:id]).present? ? current_user.assets.find_by_id(params[:id]) : []
    if params[:folderid].present?
      folderA = Asset.find_by_id(params[:id])
      folder_asset = Asset.find_by_folder_id(folderA.folder_id)
    end
    #if not found in own assets, check if the current_user has share access to the parent folder of the File 
    # debugger
    # asset ||= Asset.find(params[:id]) if current_user.has_share_access?(Asset.find_by_id(params[:id]).folder) 
    
    if asset.present? 
    # Download file from application's assets folder
      send_file asset.uploaded_file.path, :type => asset.uploaded_file_content_type 
    #Download file from AWS s3 Bucket
     #Parse the URL for special characters first before downloading 
     # data = open(URI.parse(URI.encode(asset.uploaded_file.url))) 
     # send_data data, :filename => asset.uploaded_file_file_name 
     # send_file asset asset.uploaded_file.path, :type => asset.uploaded_file_content_type
     # redirect_to asset.uploaded_file.url 
    elsif folder_asset.present?
      send_file folder_asset.uploaded_file.path, :type => folder_asset.uploaded_file_content_type          
    else
     flash[:error] = "Don't be cheeky! Mind your own assets!"
     redirect_to root_url 
    end
  end

  private
    def set_asset
      @asset = Asset.find(params[:id])
    end

    def asset_params
      # params.require(:asset).permit(:user_id)    
      params.require(:asset).permit(:uploaded_file,:user_id,:folder_id)
    end
end
