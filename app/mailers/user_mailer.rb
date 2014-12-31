class UserMailer < ActionMailer::Base 
  default :from => "rick.chauhan@sooryen.com"
    
  def invitation_to_share(shared_folder) 
    @shared_folder = shared_folder 
    mail( :to => @shared_folder.shared_email,  
          :subject => " wants to share  folder with you" ) 
  end
end
