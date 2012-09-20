ActionView::Base.field_error_proc = Proc.new do |html_tag,instance|
  tag = %(<div class="fieldWithErrors">#{html_tag}</div>)
  unless html_tag[/<label/]
    tag += %(<div class="validation-error">#{instance.error_message}</div>)
  end
  tag
end
