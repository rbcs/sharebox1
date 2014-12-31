class FoldersController < ApplicationController

  require 'rubygems'
  require 'zip'
  require "open-uri"

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

  def folder_dir(download_folder)
    @shared_sub_folder ||= []
    @pf = Folder.find_by_id(download_folder)
    Folder.where(:parent_id => download_folder).each do |a|
      if a.parent_id.present?
        @shared_sub_folder << {"id" => "#{a.id}","name" => "#{a.name}","head_id" => "#{a.parent_id}"}
        folder_dir(a)
      end
    end
    return @shared_sub_folder
    # if Folder.where(:parent_id => download_folder.id).present?
    #   Folder.where(:parent_id => download_folder.id).each do |f|
    #     return z.put_next_entry("#{f.name}/#{z.put_next_entry(folder_dir(z,f))}")
    #   end
    # end 
  end

  def put_next_entry(data,z)
      @a = []
      data.each do |item|
        item['children'] = data.select { |_item| _item['head_id'] == item['id'] }
        debugger
        item['children'].map{|i| i['name']}.each do |f|
          @a << z.put_next_entry("#{f}/")  
        end
        # item['children'] = z.put_next_entry("#{data.select { |_item| _item['head_id'] == item['id'] }.map{|i| i['name']}}")
        # z.put_next_entry("#{data.select { |_item| _item['head_id'] == item['id'] }}/#{item['children']}")
        # debugger
      end
      z.put_next_entry("#{data.select { |item| item['head_id'] == nil }.map{|i| i['name']}}/#{@a}")
      # debugger
  end

  def download_folder
    @download_folder = Folder.find_by_id(params[:id])
    @all_folder = folder_dir(params[:id])
    @Folder_hash = @all_folder.insert(0,{"id"=>"#{params[:id]}","name" => "#{@download_folder.name}" ,"head_id"=>nil})
    # @f_hash = pp to_tree(@Folder_hash)
    zip_entry = []
    t = Tempfile.new("my")
    a = Tempfile.new("my1")
    Zip::OutputStream.open(t.path) do |z|
      Asset.where(:folder_id => @download_folder).each do |i|
        title = i.uploaded_file_file_name
        put_next_entry(@Folder_hash,z)
        debugger
        # z.put_next_entry("#{@download_folder.name}/#{z.put_next_entry(Folder.where(:parent_id => @download_folder.id).map{|i| i.name}.first)}/")
        # z.put_next_entry("#{@download_folder.name}/#{title}")
        url1 = i.uploaded_file.path
        url1_data = open(url1)
        z.print IO.read(url1_data)
      end
    end

    send_file t.path, :type => 'application/zip', :disposition => 'attachment', :filename => "#{@download_folder.name}"
    t.close

    # @folder = Folder.find(params[:id])
    # temp = Tempfile.new('attachment.zip')
    # # debugger
    # Zip::ZipOutputStream.open(temp.path) do |z|
    #   Folder.where(:parent_id => @folder.id).each do |file|
    #     z.put_next_entry(file.name)
    #     # debugger
    #     z.print IO.read(temp.path)
    #   end
    # end
    # send_file temp.path, :type => 'application/zip', :disposition => 'attachment', :filename => "#{@folder.name}.zip"
    # temp.delete() #To remove the tempfile
    # # debugger
  end

  def update
    @folder.update(folder_params)
    redirect_to browse_path(folder_params[:parent_id].present? ? @folder.parent : @folder)
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
