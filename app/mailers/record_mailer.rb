# -*- encoding : utf-8 -*-
# Only works for documents with a #to_marc right now. 
class RecordMailer < ActionMailer::Base
  def email_record(documents, details, url_gen_params)
    #raise ArgumentError.new("RecordMailer#email_record only works with documents with a #to_marc") unless document.respond_to?(:to_marc)
        
    subject = I18n.t('blacklight.email.text.subject', :count => documents.length, :title => (documents.first.to_semantic_values[:title] rescue 'N/A') )

    @documents      = documents
    @message        = details[:message]
    @url_gen_params = url_gen_params

    mail(:from => "youremail@yourserver.edu", :to => details[:to],  :subject => subject)
  end
  
  def sms_record(documents, details, url_gen_params)
    @documents      = documents
    @url_gen_params = url_gen_params
    mail(:from => "youremail@yourserver.edu", :to => details[:to], :subject => "")
  end

end
