# -*- encoding : utf-8 -*-
# This module provides the body of an email export based on the document's semantic values

# gboushey on 4-25-14
# override to provide our solr responses
module Blacklight::Solr::Document::Email

  # Return a text string that will be the body of the email
  def to_email_text
    body = []
  
    body << I18n.t('blacklight.email.text.title', :value => self[:ti]) unless self[:ti].blank?
    body << I18n.t('blacklight.email.text.author', :value => self[:au]) unless self[:au].blank?
    body << I18n.t('blacklight.email.text.language', :value => self[:language] ) unless self[:language].blank?
    return body.join("\n") unless body.empty?
  end

end