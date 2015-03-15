class HomeController < ApplicationController

  def index
    @ref = params['ref']
  end

  def interested

    # basic email check before any processing
    if (params['email'].blank? or params['email'] !~ /\A[^@\s]+@([^@.\s]+\.)+[^@.\s]+\z/)
      flash.now[:error] = []
      flash.now[:error] << 'Your email address was not recognised. Please try again.'
      return render 'subscribe_error.js.erb'
    end

    ref   = params['ref']
    email = params['email']
    name  = params['name']

    # process lead's mailchimp signup
    result = Lead.mailchimp_signup(name, email, ref)

    if result[:errors].any? # there were problems with processing signup
      flash.now[:error] = []
      result[:errors].each do |error|
        flash.now[:error] << error[:message]
      end
      return render 'subscribe_error.js.erb'
    elsif !result[:data][:rcode].nil? # the lead has already signed up
      @rcount = result[:data][:rcount]
      @rcode  = result[:data][:rcode]
      return render 'stats.js.erb'
    else # lead is new and was processed successfully
      @rcode = Lead.where(:email => email).limit(1).pluck(:referral_code).first
      @rcount = 0
      flash.now[:success] = "Please check the email we've sent you to confirm your subscription."
      return render 'interested.js.erb'
    end
  end
  
  # Method for contact form
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