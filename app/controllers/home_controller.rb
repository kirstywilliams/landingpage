class HomeController < ApplicationController

  def index
    @ref = params['ref']
  end

  def interested
    require 'mailchimp'
    require 'digest'

    if (params['email'].blank? or params['email'] !~ /\A[^@\s]+@([^@.\s]+\.)+[^@.\s]+\z/)
      flash.now[:error] = 'Your email address was not recognised. Please try again.'
      return render 'subscribe_error.js.erb'
    end

    @ref           = params['ref']
    email          = params['email']
    @referral_code = Digest::MD5.hexdigest(email)
    name           = params['name']

    begin
      mailchimp = Mailchimp::API.new(MAILCHIMP_API_KEY)
    rescue => e
      flash.now[:error] = 'Oops, something went wrong. Please try again later.'
      return render 'subscribe_error.js.erb'
    end

    begin
      lead_info = mailchimp.lists.member_info(MAILCHIMP_LIST_ID, ['email' => "#{email}"])
    rescue => e
      flash.now[:error] = 'There was a problem getting info on this email address.'
      return render 'subscribe_error.js.erb'
    end

    if lead_info['errors'].any?
      lead_info['errors'].each do |error|
        if error['code'] == 232 # The user is not in the list
          unless @ref.blank? # Increment RCOUNT for referrer if referral code is present
            begin
              referrer = Lead.where(referral_code: "#{@ref}").first
              new_count = referrer.referral_count + 1
              referrer.update_attributes!(referral_count: new_count)
              referrer.save
              
              referring_member = mailchimp.lists.member_info("#{MAILCHIMP_LIST_ID}", [{'email' => referrer.email}])
              result = mailchimp.lists.update_member("#{MAILCHIMP_LIST_ID}", {'email' => referrer.email}, {'RCOUNT' => referrer.referral_count})
              referring_member = mailchimp.lists.member_info("#{MAILCHIMP_LIST_ID}", [{'email' => referrer.email}])
              
            rescue => e
              flash.now[:error] = 'There was a problem updating the referral at MailChimp.'
              return render 'subscribe_error.js.erb'
            end
          end

          begin
            lead = Lead.where(email: email).first_or_create
            lead.update_attributes(name: name)
            
            success = mailchimp.lists.subscribe("#{MAILCHIMP_LIST_ID}",
                                      {'email' => "#{email}"},
                                      {'NAME' => "#{name}", 
                                      'RCODE' => "#{@referral_code}", 
                                      'RCOUNT' => '0'}, 
                                      "double_optin" => false, 
                                      "send_welcome" => true)
            
            flash.now[:success] = "Please check the email we've sent you to confirm your subscription."
            return render 'interested.js.erb'
          rescue => e
            flash.now[:error] = 'There was a problem subscribing you to the list on MailChimp.'
            Rails.logger.info("error: #{e.message}")
            return render 'subscribe_error.js.erb'
          end
        end
      end
    else # The user is in the list
      @rcount = lead_info['data'][0]['merges']['RCOUNT']
      @rcode  = lead_info['data'][0]['merges']['RCODE']
      return render 'stats.js.erb'
    end
  end
  
  def dispatch_email
    lead_info = params[:lead_info]
    if ContactMailer.send_email(lead_info).deliver
      flash.now[:success] = "Great, your message has been sent! We'll try to respond as soon as possible."
    else
      flash.now[:error] = "Oops, there seems to be a problem. Please email us at info@page-one.co."
    end
    
    respond_to do |format|
      format.js
    end
  end
end