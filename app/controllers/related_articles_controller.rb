class RelatedArticlesController < ApplicationController
  
  def new
    @related_article = RelatedArticle.new
    @title = 'Submit related article/blog post'
  end
  
  def create
    pingback = Pingback.new(params[:related_article][:url], params[:related_article][:openlylocal_url])
    
    flash[:notice] = 
      if pingback.receive_ping.is_a?(String) && RelatedArticle.process_pingback(pingback) 
      "Successfully added link to related article"
      else
        "Could not add link. Please check the site is listed in the hyperlocal directory and you are linking to the OpenlyLocal URL submitted"
      end
    redirect_to new_related_article_url
  end
end
