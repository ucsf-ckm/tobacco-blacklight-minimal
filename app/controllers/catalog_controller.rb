require 'net/http'

# Lengthen timeout in Net::HTTP
module Net
    class HTTP
        alias old_initialize initialize

        def initialize(*args)
            old_initialize(*args)
            @read_timeout = 5*60     # 5 minutes
        end
    end
end
# turn on logging
BLACKLIGHT_VERBOSE_LOGGING = false

# -*- encoding : utf-8 -*-
#
class CatalogController < ApplicationController  
  include Blacklight::Marc::Catalog

  include Blacklight::Catalog

  configure_blacklight do |config|
    ## Default parameters to send to solr for all search-like requests. See also SolrHelper#solr_search_params
    config.default_solr_params = {
      :qt => 'search',
      :rows => 10,
      :fl => 'dt pg bn source dd ti id score dddate', #dddate is for debug
      :hl => true,
      :'hl.fl' => 'dt pg bn source dd',
      :'f.dt.hl.alternateField' => 'dt',
      :'f.pg.hl.alternateField' => 'pg',
      :'f.bn.hl.alternateField' => 'bn',
      :'f.source.hl.alternateField' => 'source',
      :'f.dd.hl.alternateField' => 'dd',
      :'hl.simple.pre' => '<span class="label label-info">',
      :'hl.simple.post' => '</span>',
      # view/catalog/index.html.erb, overrode for group to work
      # view/catalog/_group_default.html.erb, overrode for group to work
      # lib/blacklight/solr_helper.rb, overrode for group to work with bookmarks
      :group => true,
      :'group.field' => 'signature',
      :'group.limit' => 1,
      :'group.ngroups' => true
    }

    ## Default parameters to send on single-document requests to Solr. These settings are the Blackligt defaults (see SolrHelper#solr_doc_params) or 
    ## parameters included in the Blacklight-jetty document requestHandler.
    
    #config.default_document_solr_params = {
    # :qt => 'document',
    #  ## These are hard-coded in the blacklight 'document' requestHandler
    #   :fl => '*',
    #   :rows => 1,
    #   :q => '{!raw f=id v=$id}'
    #}

    # solr field configuration for search results/index views
    config.index.title_field = 'ti'
    #config.index.display_type_field = 'format'
    config.index.group = 'signature'

    # solr field configuration for document/show views
    config.show.title_field = 'ti'
    config.show.heading = 'ti'
    #config.show.display_type_field = 'format'

    # solr fields that will be treated as facets by the blacklight application
    #   The ordering of the field names is the order of the display
    #
    # Setting a limit will trigger Blacklight's 'more' facet values link.
    # * If left unset, then all facet values returned by solr will be displayed.
    # * If set to an integer, then "f.somefield.facet.limit" will be added to
    # solr request, with actual solr request being +1 your configured limit --
    # you configure the number of items you actually want _displayed_ in a page.    
    # * If set to 'true', then no additional parameters will be sent to solr,
    # but any 'sniffed' request limit parameters will be used for paging, with
    # paging at requested limit -1. Can sniff from facet.limit or 
    # f.specific_field.facet.limit solr request params. This 'true' config
    # can be used if you set limits in :default_solr_params, or as defaults
    # on the solr side in the request handler itself. Request handler defaults
    # sniffing requires solr requests to be made with "echoParams=all", for
    # app code to actually have it echo'd back to see it.  
    #
    # :show may be set to false if you don't want the facet to be drawn in the 
    # facet bar
    #Industry
    config.add_facet_field 'industry', :label => 'Industry', :show => false
    # Source
    config.add_facet_field 'source_facet', :label => 'Source', :show => false
    #Industry -> Source
    config.add_facet_field 'industry_source_pivot_field', :label => 'Industry/Source', :pivot => ['industry', 'source_facet']
    #Originating collection
    #config.add_facet_field 'origcn', :label => 'Originating Collection' #mm collection will be absorbed into originating collection, this field will be removed
    #Author per
    config.add_facet_field 'au_facet', :label => 'Author', :limit => 15
    #Company
    config.add_facet_field 'co', :label => 'Company'

    #Document date
    config.add_facet_field 'dddate', :label => 'Document Date', :query => {
        :years_5 => { :label => 'within 5 Years', :fq => 'dddate:[NOW-5YEAR TO *]' },
        :years_10 => { :label => '5 - 10 Years', :fq => 'dddate:[NOW-10YEAR TO NOW-5YEAR]' },
        :years_25 => { :label => '10 - 25 Years', :fq => 'dddate:[NOW-25YEAR TO NOW-10YEAR]' },
        :years_50 => { :label => '25 - 50 Years', :fq => 'dddate:[NOW-50YEAR TO NOW-25YEAR]' },
        :years_75 => { :label => '50 -75 Years', :fq => 'dddate:[NOW-75YEAR TO NOW-50YEAR]' },
        :years_100 => { :label => '75 - 100 Years', :fq => 'dddate:[NOW-100YEAR TO NOW-75YEAR]' },
        :years_B4_100 => { :label => 'before 100 Years', :fq => 'dddate:[* TO NOW-100YEAR]' },
        :no_date => {:label => 'no date', :fq => "-dddate:*"}
   }

    #Drug
    config.add_facet_field 'dg', :label => 'Drug', :limit => 15
    #Document type
    config.add_facet_field 'dt', :label => 'Document Type', :limit => 15
    #Mentioned per
    #config.add_facet_field 'men_facet', :label => 'Mentioned', :limit => 15
    #Ddu 
    config.add_facet_field 'ddudate', :label => 'Date Added UCSF', :query => {
        :within_6_mo => { :label => 'within 6 Months', :fq => 'ddudate:[NOW-6MONTH TO *]' },
        :between_6_12_mo => { :label => '6 - 12 Months', :fq => 'ddudate:[NOW-12MONTH TO NOW-6MONTH]' },
        :between_1_2_yr => { :label => '1 - 2 Years', :fq => 'ddudate:[NOW-2YEAR TO NOW-1YEAR]' },
        :between_2_4_yr => { :label => '2 - 4 Years', :fq => 'ddudate:[NOW-4YEAR TO NOW-2YEAR]' },
        :between_4_6_yr => { :label => '4 - 6 Years', :fq => 'ddudate:[NOW-6YEAR TO NOW-4YEAR]' },
        :between_6_8_yr => { :label => '6 - 8 Years', :fq => 'ddudate:[NOW-8YEAR TO NOW-6YEAR]' },
        :between_8_10_yr => { :label => '8 - 10 Years', :fq => 'ddudate:[NOW-10YEAR TO NOW-8YEAR]' },
        :before_10_yr => { :label => 'before 10 Years', :fq => 'ddudate:[* TO NOW-10YEAR]' },
        :no_date => {:label => 'no date', :fq => '-ddudate:*'}
   }

    config.add_facet_field 'pgint', :label => 'Pages', :range => true
    #Person facet
    config.add_facet_field 'per_facet', :label => 'Person', :limit => 15
    #Org
    config.add_facet_field 'org_facet', :label => 'Organization', :limit => 15

    #signature, this is so that the see more query would work. But don't want to display it
    config.add_facet_field 'signature', :label => 'signature', :show => false
    


    # Have BL send all facet field names to Solr, which has been the default
    # previously. Simply remove these lines if you'd rather use Solr request
    # handler defaults, or have no facets.
    config.add_facet_fields_to_solr_request!

    # solr fields to be displayed in the index (search results) view
    #   The ordering of the field names is the order of the display 
    #Document Date 
    #Document Type 
    #Bates 
    #Source
    #Pages
    config.add_index_field 'dd', :label => 'Document date', :highlight => true
    config.add_index_field 'dt', :label => 'Document type', :highlight => true
    config.add_index_field 'bn', :label => 'Bates number', :highlight => true
    config.add_index_field 'source', :label => 'Source', :highlight => true
    config.add_index_field 'pg', :label => 'Pages', :highlight => true
    #the fields below are for debugging
    config.add_index_field 'score', :label => 'Relevance score'
    config.add_index_field 'dddate', :label => 'Document Date (date)'

    # solr fields to be displayed in the show (single result) view
    #   The ordering of the field names is the order of the display 

    #Title(ti)
    config.add_show_field 'ti', :label => 'Title'
    #Access (access)
    config.add_show_field 'access', :label => 'Access'
    #Adverse Ruling (adr)
    config.add_show_field 'adr', :label => 'Adverse Ruling'
    #Area (area)
    config.add_show_field 'area', :label => 'Area'
    #Attending (at)
    config.add_show_field 'at', :label => 'Attending'
    #Physical Attachments (attach)
    config.add_show_field 'attach', :label => 'Physical Attachments'
    #Author (au)
    config.add_show_field 'au', :label => 'Author'
    #Bates Number (bn)
    config.add_show_field 'bn', :label => 'Bates Number'
    #Alternate Bates (bnalias)
    config.add_show_field 'bnalias', :label => 'Alternate Bates'
    #Box (box)
    config.add_show_field 'box', :label => 'Box'
    #Brands (brd)
    config.add_show_field 'brd', :label => 'Brands'
    #Bates Defendant (brdef)
    config.add_show_field 'brdef', :label => 'Bates Defendant'
    #Bates Plaintiff (brplaint)
    config.add_show_field 'brplaint', :label => 'Bates Plaintiff'
    #Case ID (caseid)
    config.add_show_field 'caseid', :label => 'Case ID'
    #Case Name (casename)
    config.add_show_field 'casename', :label => 'Case Name'
    #Copied (cc)
    config.add_show_field 'cc', :label => 'Copied'
    #Source (src)
    config.add_show_field 'source', :label => 'Source'
    #Characteristics (cond)
    config.add_show_field 'cond', :label => 'Characteristics'
    #Corporation (corp)
    config.add_show_field 'focorprmat', :label => 'Corporation'
    #Court (crt)
    config.add_show_field 'crt', :label => 'Court'
    #Country (ct)
    config.add_show_field 'ct', :label => 'Country'
    #Document Date (dd)
    config.add_show_field 'dd', :label => 'Document Date'
    #Date Added Industry (ddi)
    config.add_show_field 'ddi', :label => 'Date Added Industry'
    #Date Modified (ddm)
    config.add_show_field 'ate Modified', :label => 'ddm'
    #Date Modified UCSF (ddmu)
    config.add_show_field 'ddmu', :label => 'Date Modified UCSF'
    #Date Produced (ddprod)
    config.add_show_field 'ddprod', :label => 'Date Produced'
    #Date Shipped (ddship)
    config.add_show_field 'ddship', :label => 'Date Shipped'
    #Date Added UCSF (ddu)
    config.add_show_field 'ddu', :label => 'Date Added UCSF'
    #Description (desc)
    config.add_show_field 'desc', :label => 'Description'
    #Document Format (df)
    config.add_show_field 'df', :label => 'Document Format'
    #Deposition Date (dpdt)
    config.add_show_field 'dpdt', :label => 'Deposition Date'
    #Privilege log date (dpl)
    config.add_show_field 'dpl', :label => 'Privilege log date'
    #Document Type (dt) 
    config.add_show_field 'dt', :label => 'Document Type'
    #Express Waiver (exw)
    config.add_show_field 'exw', :label => 'Express Waiver'
    #File Number (fn)
    config.add_show_field 'fn', :label => 'File Number'
    #Genre (genre)
    config.add_show_field 'genre', :label => 'Genre'
    #Grant (grantnum)
    config.add_show_field 'grantnum', :label => 'Grant'
    #Journal Citation (journal)
    config.add_show_field 'journal', :label => 'Journal Citation'
    #Keywords (kw)
    config.add_show_field 'kw', :label => 'Keywords'
    #Language (lg) 
    config.add_show_field 'lg', :label => 'Language'
    #Master Bates (mbn)
    config.add_show_field 'mbn', :label => 'Master Bates'
    #Mentioned (men)
    config.add_show_field 'men', :label => 'Mentioned'
    #Notes (notes) 
    config.add_show_field 'notes', :label => 'Notes'
    #Other Corporations (ocorp)
    config.add_show_field 'ocorp', :label => 'Other Corporations'
    #Oklahoma Downgrades (od)
    config.add_show_field 'od', :label => 'Oklahoma Downgrades'
    #Originating Collection (origcn)
    config.add_show_field 'origcn', :label => 'Originating Collection'
    #Other Number (othernum)
    config.add_show_field 'othernum', :label => 'Other Number'
    #Pages (pg)
    config.add_show_field 'pg', :label => 'Pages'
    #Page Count Notes (pgdisp)
    config.add_show_field 'pgdisp', :label => 'Page Count Notes'
    #Page Map (pgmap)
    config.add_show_field 'pgmap', :label => 'Page Map'
    #Recipients (rc) 
    config.add_show_field 'rc', :label => 'Recipients'
    #Redacted (redact)
    config.add_show_field 'redact', :label => 'Redacted'
    #Referenced Documents (refdoc)
    config.add_show_field 'refdoc', :label => 'Referenced Documents'
    #Request Number (reqno)
    config.add_show_field 'reqno', :label => 'Request Number'
    #Minnesota Request Number (rnm)
    config.add_show_field 'rnm', :label => 'Minnesota Request Number'
    #Other Request (rno)
    config.add_show_field 'rno', :label => 'Other Request'
    #Series (series) 
    config.add_show_field 'series', :label => 'Series'
    #Special Collections (speccoll) 
    config.add_show_field 'speccoll', :label => 'Special Collections'
    #Document Status (st)
    config.add_show_field 'st', :label => 'Document Status'
    #Exhibit Number (en)
    config.add_show_field 'en', :label => 'Exhibit Number'
    #ID 
    config.add_show_field 'id', :label => 'ID'
    #TID (tid)
    config.add_show_field 'tid', :label => 'TID'
    #Topic (topic)
    config.add_show_field 'topic', :label => 'Topic'
    #Litigation Usage (usage)
    config.add_show_field 'usage', :label => 'Litigation Usage'
    #Witness (w)
    config.add_show_field 'w', :label => 'Witness'
    #OCR text (ot)
    config.add_show_field 'ot', :label => 'OCR Text'
    

    # "fielded" search configuration. Used by pulldown among other places.
    # For supported keys in hash, see rdoc for Blacklight::SearchFields
    #
    # Search fields will inherit the :qt solr request handler from
    # config[:default_solr_parameters], OR can specify a different one
    # with a :qt key/value. Below examples inherit, except for subject
    # that specifies the same :qt as default for our own internal
    # testing purposes.
    #
    # The :key is what will be used to identify this BL search field internally,
    # as well as in URLs -- so changing it after deployment may break bookmarked
    # urls.  A display label will be automatically calculated from the :key,
    # or can be specified manually to be different. 

    # This one uses all the defaults set by the solr request handler. Which
    # solr request handler? The one set in config[:default_solr_parameters][:qt],
    # since we aren't specifying it otherwise. 
    
    #er
    config.add_search_field 'er', :label => 'Entire Record'
    #title
    config.add_search_field('Title') do |field|
      field.solr_local_parameters = {
        :qf => 'ti',
      }
    end    
    #per
    config.add_search_field('Person') do |field|
      field.solr_local_parameters = {
        :qf => 'per',
      }
    end
    #org
    config.add_search_field('Organization') do |field|
      field.solr_local_parameters = {
        :qf => 'org',
      }
    end
    #document type (dt)
    config.add_search_field('Document Type') do |field|
      field.solr_local_parameters = { 
        :qf => 'dt',
      }
    end
    #Brand Name (brd)
    config.add_search_field('Brand Name') do |field|
      field.solr_local_parameters = {
        :qf => 'brd',
      }
    end
    #Bates (bn)
    config.add_search_field('Bates Number') do |field|
      field.solr_local_parameters = {
        :qf => 'bn',
      }
    end
    #Id Number (id)
    config.add_search_field('ID') do |field|
      field.solr_local_parameters = {
          :qf => 'id',
      }
    end
    #metadata (md)
    config.add_search_field('Metadata') do |field|
      field.solr_local_parameters = {
          :qf => 'md',
      }
    end    
    #OCR Text (ot)
    config.add_search_field('OCR Text') do |field|
      field.solr_local_parameters = {
          :qf => 'ot',
      }
    end

 

    # Now we see how to over-ride Solr request handler defaults, in this
    # case for a BL "search field", which is really a dismax aggregate
    # of Solr search fields. 
    

    # "sort results by" select (pulldown)
    # label in pulldown is followed by the name of the SOLR field to sort by and
    # whether the sort is ascending or descending (it must be asc or desc
    # except in the relevancy case).
    # For LTDL3
    config.add_sort_field 'score desc, dddatelatest desc, ti asc', :label => 'Relevance'
    config.add_sort_field 'dddatelatest desc, ti asc', :label=> 'Document Date (new to old)'
    config.add_sort_field 'dddatelatest asc, ti asc', :label=> 'Document Date (old to new)'
    config.add_sort_field 'ddidatelatest desc, ti asc', :label=> 'Date Added Industry (new to old)'
    config.add_sort_field 'ddidatelatest asc, ti asc', :label=> 'Date Added Industry (old to new)'
    config.add_sort_field 'pgint desc, ti asc', :label => 'Page Count (high to low)'
    config.add_sort_field 'pgint asc, ti asc', :label => 'Page Count (low to high)'
    config.add_sort_field 'bn desc, ti asc', :label=> 'Bates Number (high to low)'
    config.add_sort_field 'bn asc, ti asc', :label => 'Bates Number (low to high)'

    # If there are more than this many search results, no spelling ("did you 
    # mean") suggestion is offered.
    config.spell_max = 5
  end
  
end
