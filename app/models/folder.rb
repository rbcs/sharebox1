class Folder < ActiveRecord::Base
	acts_as_tree
	belongs_to :user
	has_many :assets, :dependent => :destroy
	has_many :share_folders, :dependent => :destroy

	def shared?
		!self.share_folders.empty?
	end

end
