class HomeController < ApplicationController
	require 'pp'

	# def find_recursive_with arg, options = {}
	#     map do |e|
	#       first = e[arg]
	#       unless e[options[:nested]].blank?
	#         others = e[options[:nested]].find_recursive_with(arg, :nested => options[:nested])
	#       end
	#       [first] + (others || [])
	#     end.flatten.compact
	# end

	def index
		if user_signed_in?
			@sharedfolder_array = ShareFolder.where(:shared_user => current_user.id)
			@current_user_shared_folder_array = @sharedfolder_array.map{|i| i.folder_id.present? ? YAML::load(i.folder_id) : nil}
			@shared_parent_id = []
			@current_user_shared_folder_array.each do |c|
				@shared_parent_id << c.map{|h| h['id']}.flatten.map(&:to_i).uniq
			end			
			@Shared_Pfolder = @shared_parent_id.flatten
			@being_shared_folders = Folder.where('id IN (?)',@Shared_Pfolder)
			
			# @allSahredfolder = @current_user_shared_folder_array.to_s.scan(/(?<=\"id\"=>\")\d+/).map(&:to_i)
			# @allSahredfolder = @current_user_shared_folder_array.find_recursive_with "id", :nested => "children"

			# debugger
			# @YAML_sharedfolder = []
			# @sharedfolder_array = ShareFolder.where(:shared_user => current_user.id)
			# @current_user_shared_folder_array = @sharedfolder_array.map{|i| i.folder_id}.compact.map{|b| b.scan(/\d+/).join(',')}.uniq
			# @shared_parent_folder_id = @current_user_shared_folder_array.map{|i| i.scan(/\d+/).uniq.first.to_i}.uniq
			# @being_shared_folders = Folder.where('id IN (?)',@shared_parent_folder_id)
			# @being_shared_folders = current_user.shared_folders_by_others 
			@folders = current_user.folders.roots
			@assets = current_user.assets.where("folder_id is NULL").order("uploaded_file_file_name desc")
		end
	end

	def browse 
	  #first find the current folder within own folders
	  @current_folder = current_user.folders.find_by_id(params[:folder_id])
	  @shared_folders = Folder.where(:parent_id => params[:folder_id])
	  # @is_this_folder_being_shared = false if @current_folder #just an instance variable to help hiding buttons on View 
	  #if not found in own folders, find it in being_shared_folders 
	  # @shared_folders = current_user.shared_folders_by_others
	  # @browse_folder_id = @sharedfolder_array.map{|i| i.folder_id}.compact.map{|b| b.scan(/\d+/).join(',')}.uniq.join(',').split(',').compact
	  
	  if @current_folder.nil? 
	    folder = Folder.find_by_id(params[:folder_id]) 
	  	@being_shared_folders = Folder.find_by_parent_id(params[:folder_id])
	    @current_folder ||= folder if current_user.has_share_access?(folder) 
	    @is_this_folder_being_shared = true if @current_folder #just an instance variable to help hiding buttons on View   
	  end
	  
	  if @current_folder.present?
	  	@being_shared_folders = []
	  	@folders = @current_folder.children
	  	@assets = @current_folder.assets.order("uploaded_file_file_name desc") 
	  	render :action => "index"
	  elsif @shared_folders.present?
	  	@folders = []
	    @being_shared_folders = @shared_folders 	  
	    @assets = Asset.where(:folder_id => params[:folder_id]) 
	    render :action => "index"
	  else
	  	flash[:error] = "Don't be cheeky! Mind your own assets!"
	    redirect_to root_url 
	  end

	  # if @current_folder
	  #   #if under a sub folder, we shouldn't see shared folders 
	  #   @being_shared_folders = Folder.where(:parent_id => params[:folder_id]).present? ? Folder.where(:parent_id => params[:folder_id]) : []
	  #   debugger
	  #   # @being_shared_folders = [] 
	  #   #show folders under this current folder 
	  #   @folders = @current_folder.children 	      
	  #   #show only files under this current folder 
	  #   @assets = @current_folder.assets.order("uploaded_file_file_name desc") 
	  #   render :action => "index"
	  # else
	  #   flash[:error] = "Don't be cheeky! Mind your own assets!"
	  #   redirect_to root_url 
	  # end
	end

	def share     
	    email_addresses = params[:email_addresses].split(",") 
	    
	    #Hash Example
	    # @hash_user_shared_folder = [{"id"=>"5", "name"=>"sub_tests10", "head_id"=>nil},{"id"=>"19", "name"=>"sub_tests10", "head_id"=>"5"}, {"id"=>"21", "name"=>"sub_of_sub_test10", "head_id"=>"19"}, {"id"=>"20", "name"=>"sub_test10_1", "head_id"=>"5"}, {"id"=>"22", "name"=>"sub_sub_test10_1", "head_id"=>"20"}, {"id"=>"23", "name"=>"sub_sub_test10_2", "head_id"=>"20"}]

	    @user_shared_folders_hash = get_all_shared_sub_folders(params[:folder_id]) 
	    # debugger
	    @Folder_hash = @user_shared_folders_hash.insert(0,{"id"=>"#{params[:folder_id]}", "head_id"=>nil})
	    # debugger
	    @user_shared_folder = pp to_tree(@Folder_hash)

	    email_addresses.each do |email_address| 	   
	      @shared_folder = current_user.share_folders.new
	      @shared_folder.folder_id = @user_shared_folder
	      @shared_folder.shared_email = email_address 	    
	      shared_user = User.find_by_email(email_address) 
	      @shared_folder.shared_user_id = shared_user.id if shared_user 
	      @shared_folder.message = params[:message] 
	      @shared_folder.save 
	  		UserMailer.invitation_to_share(@shared_folder).deliver
	    end
	   
	    respond_to do |format| 
	      	format.js { 
	      	} 
	    end
	end

 	def get_all_shared_sub_folders(folder_id)
 		@shared_sub_folder ||= []
 		@pf = Folder.find_by_id(folder_id)
 		Folder.where(:parent_id => folder_id).each do |a|
 			if a.parent_id.present?
 				@shared_sub_folder << {"id" => "#{a.id}","head_id" => "#{a.parent_id}"}
 				get_all_shared_sub_folders(a.id)
 			end
 		end
 		return @shared_sub_folder
 	end

 	def to_tree(data)
	  	data.each do |item|
	    	item['children'] = data.select { |_item| _item['head_id'] == item['id'] }
	  	end
	  	data.select { |item| item['head_id'] == nil }
	end

end
