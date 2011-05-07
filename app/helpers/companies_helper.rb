module CompaniesHelper
  def payer_breakdown_table(payer_breakdown_data=[])
    return if payer_breakdown_data.blank?
    headings = ['Payed By', 'Total Spend', 'Average Monthly Spend']
    classes = ['description', 'value', 'value']
    content = ''
    content << content_tag(:caption, 'Payer breakdown')
    i = 0
    content << content_tag(:tr) do
      headings.collect do |heading|
        i+=1
        content_tag(:th, heading, :class => classes[i-1])
      end
    end
    payer_breakdown_data.each do |org, org_data|
      org_data[:elements].each do |sr|
        content << content_tag(:tr, :class => 'element', :style => 'display:none') do
          content_tag(:td, basic_link_for(sr, :text => "#{org.title} (#{sr.title})"), :class => classes[0]) +
          content_tag(:td, number_to_currency(sr.total_spend.to_i, :unit => '&pound;', :precision => 0), :class => classes[1]) +
          content_tag(:td, number_to_currency(sr.average_monthly_spend.to_i, :unit => '&pound;', :precision => 0), :class => classes[2])
        end.to_s
      end
      content << content_tag(:tr, :class => 'subtotal') do
        subtotal_data = org_data[:subtotal]
        content_tag(:td, "#{org.title} <span class='description' style='display:none'>subtotal</span>", :class => classes[0]) +
        content_tag(:td, number_to_currency(subtotal_data[1], :unit => '&pound;', :precision => 0), :class => classes[1]) +
        content_tag(:td, number_to_currency(subtotal_data[2], :unit => '&pound;', :precision => 0), :class => classes[2])
      end
    end
    content_tag(:table, :class => 'statistics', :id => 'payer_breakdown') { content }
  end
end
