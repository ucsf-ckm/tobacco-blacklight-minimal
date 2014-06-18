require "#{Blacklight.root}/app/controllers/bookmarks_controller"

# -*- encoding : utf-8 -*-
# note that while this is mostly restful routing, the #update and #destroy actions
# take the Solr document ID as the :id, NOT the id of the actual Bookmark action. 
class BookmarksController < CatalogController

  before_filter :verify_user

  ##
  # Give Bookmarks access to the CatalogController configuration
  include Blacklight::Configurable
  include Blacklight::SolrHelper

  def index
    
     @bookmarks = current_or_guest_user.bookmarks
     bookmark_ids = @bookmarks.collect { |b| b.document_id.to_s }

     @response, @document_list = get_solr_response_for_field_values_for_bookmarks(SolrDocument.unique_key, bookmark_ids)
  end

end