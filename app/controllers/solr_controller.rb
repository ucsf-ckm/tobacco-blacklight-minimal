require 'rsolr'

class SolrController < ApplicationController  

  def select
    # Direct connection
    solr = RSolr.connect :url => 'http://solr1.mooo.com:8983/solr/ltdl3test/'

    # send a request to /select
    # response = solr.get 'select', :params => {:q => '*:*'}

    # send a request to /catalog
    #response = solr.get 'catalog', :params => {:q => '*:*'}

    #response = solr.get 'select', :params => {:q => params[:q], :wt => params[:wt] }
    
    response = solr.get 'select', :params => params.except(:action, :controller) 

    render json: response
  end
  
end
