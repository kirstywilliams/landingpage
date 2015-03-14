module ApplicationHelper
  
  def shorten_with_bitly(ref)
    url = "http://#{SITE_DOMAIN}/?ref=#{ref}"
    Bitly.client.shorten(url).short_url
  end

  def normalise_ext(string)
    string.gsub(" ", "+")
  end
  
  def bootstrap_class_for(flash_type)
    case flash_type
      when "success"
        "alert-success"   # Green
      when "error"
        "alert-danger"    # Red
      when "alert"
        "alert-warning"   # Yellow
      when "notice"
        "alert-info"      # Blue
      else
        flash_type.to_s
    end
  end

  def multiple_messages(flash)
  	arr = []
	  flash.each do |type, messages|
	    messages.each do |m|
	      arr << render(:partial => 'shared/flash', :locals => {:type => type, :message => m}) unless m.blank?
	    end
	  end
	  arr.join('<br/>')
	end
end