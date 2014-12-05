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
    # render :text => params and return false
    @asset = current_user.assets.new
    respond_with(@asset)
  end

  def edit
  end

  def create    
    # debugger
    @asset = current_user.assets.create(asset_params)
    @asset.save
    respond_with(@asset)
  end

  def update
    @asset.update(asset_params)
    respond_with(@asset)
  end

  def destroy
    @asset.destroy
    respond_with(@asset)
  end

  def get 
   #first find the asset within own assets 
   asset = current_user.assets.find_by_id(params[:id]) 
    
   #if not found in own assets, check if the current_user has share access to the parent folder of the File 
   debugger
   asset ||= Asset.find(params[:id]) if current_user.has_share_access?(Asset.find_by_id(params[:id]).folder) 
    
   if asset 
     #Parse the URL for special characters first before downloading 
     data = open(URI.parse(URI.encode(asset.uploaded_file.url))) 
     send_data data, :filename => asset.uploaded_file_file_name 
     #redirect_to asset.uploaded_file.url 
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
      # debugger
      params.require(:asset).permit(:uploaded_file,:user_id,:folder_id)
    end
end
