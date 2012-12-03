# require 'will_paginate/link_renderer'
class OpenlylocalLinkRenderer < WillPaginate::LinkRenderer
  
  # def pagination
  #   [ :previous_page, current_page, :next_page ]
  # end
  protected
  def windowed_page_numbers
    inner_window = @options[:inner_window].to_i
    window_from = current_page
    window_to = current_page + inner_window

    # adjust upper limit if out of bounds
    window_to = total_pages if window_to > total_pages
    left = (window_from..window_to).to_a
    left << :gap if total_pages > window_to
    left
  end
  
  def rel_value(page)
    case page
    when @collection.previous_page; 'prev nofollow' + (page == 1 ? ' start nofollow' : '')
    when @collection.next_page; 'next nofollow'
    when 1; 'start nofollow'
    else
      'nofollow'
    end
  end
end