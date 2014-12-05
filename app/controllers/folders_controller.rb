class FoldersController < ApplicationController
  before_action :set_folder, only: [:show, :edit, :update, :destroy]
  before_filter :authenticate_user!
  respond_to :html

  def index
    @folders = current_user.folders
    respond_with(@folders)
  end

  def show
    @folder = current_user.folders.find(params[:id])
    respond_with(@folder)
  end

  def new
    @folder = current_user.folders.new
    if params[:folder_id]
      @current_folder = current_user.folders.find(params[:folder_id])
      @folder.parent_id = @current_folder.id
      respond_with(@folder)
    end
  end

  def edit

    @folder = current_user.folders.find(params[:id])
    @current_folder = @folder.parent
  end

  def create
    @folder = current_user.folders.create(folder_params)
    if @folder.save 
      flash[:notice] = "Successfully created folder."  
      if @folder.parent #checking if we have a parent folder on this one 
        redirect_to browse_path(@folder.parent)  #then we redirect to the parent folder 
      else
        redirect_to root_url #if not, redirect back to home page 
      end
    else
      render :action => 'new'
    end
    # respond_with(@folder)
  end

  def update
    @folder.update(folder_params)
    respond_with(@folder)
  end

  def destroy
    @folder = current_user.folders.find(params[:id])
    @parent_folder = @folder.parent
    @folder.destroy
    flash[:notice] = "Successfully deleted the folder and all the contents inside."
    if @parent_folder 
      redirect_to browse_path(@parent_folder)
    else
      redirect_to root_url
    end
    # respond_with(@folder)
  end

  private
    def set_folder
      @folder = Folder.find(params[:id])
    end

    def folder_params
      params.require(:folder).permit(:name, :parent_id, :user_id)
    end
end
