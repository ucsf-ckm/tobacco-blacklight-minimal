require "#{Blacklight.root}/lib/blacklight/solr_helper.rb"

#author: rtang
#date: 9-April-2014
#override method in solr_helper to take group into consideration
#TODO contact blacklight user group and see if this fix should be included in the gem


module Blacklight::SolrHelper
  extend ActiveSupport::Concern
  #include Blacklight::SearchFields
  #include Blacklight::Facet
  #include ActiveSupport::Benchmarkable

  #included do
  #  if self.respond_to?(:helper_method)
  #    helper_method(:facet_limit_for)
  #  end
  #  include Blacklight::RequestBuilders
  #end



# given a field name and array of values, get the matching SOLR documents
# if group element exists, remove it because bookmarks doesn't care about groups
  def get_solr_response_for_field_values_for_bookmarks(field, values, extra_solr_params = {})
    values = Array(values) unless values.respond_to? :each

    q = if values.empty?
          "NOT *:*"
        else
          "#{field}:(#{ values.to_a.map { |x| solr_param_quote(x)}.join(" OR ")})"
        end

    solr_params = {
        :defType => "lucene",   # need boolean for OR
        :q => q,
        # not sure why fl * is neccesary, why isn't default solr_search_params
        # sufficient, like it is for any other search results solr request?
        # But tests fail without this. I think because some functionality requires
        # this to actually get solr_doc_params, not solr_search_params. Confused
        # semantics again.
        :fl => "*",
        :facet => 'false',
        :spellcheck => 'false'
    }.merge(extra_solr_params)
    solr_response = find(self.solr_search_params().merge(solr_params).update('group' => 'false'))

    document_list = solr_response.docs.collect {|doc| SolrDocument.new(doc, solr_response)}
    [solr_response, document_list]
    end

end