require 'digest'
require 'mailchimp'
class Lead < ActiveRecord::Base
	include ActiveModel::Validations

	class EmailValidator < ActiveModel::EachValidator
		def validate_each(record, attribute, value)
			record.errors.add attribute, (options[:message] || "is not a valid email") unless
			value =~ /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i
		end
	end

	before_validation :set_referral_code, :downcase_email

	validates :name, 						presence: true
	validates :referral_code,		presence: true, :if => :email_is_present?
	validates :email, 					presence: true, 
	uniqueness: { case_sensitive: false },
	email: true


	# Todo: better error handling needed.
	def self.mailchimp_signup(name, email, referral_code)

		errors = []

		# Setup mailchimp client
		begin
			mailchimp = Mailchimp::API.new(MAILCHIMP_API_KEY)
		rescue => e
			errors << {:code => "MC01" , :text => "Sorry, we cannot contact Mailchimp at this time.", :message => e.message, :data => nil }
		end

    # Retrieve lead if exists
    begin
    	lead_info = mailchimp.lists.member_info(MAILCHIMP_LIST_ID, ['email' => email])
    rescue => e
    	errors << {:code => "MC02", :text => "There was a problem getting info on this email address.", :message => e.message, :data => lead_info }
    end

    # Any errors
    if lead_info['errors'].any?
    	lead_info['errors'].each do |error|

    		# 232: User is not in the list (new lead)
    		if error['code'] == 232
	    		unless referral_code.blank? #Increment referral_count for referring lead
	    			begin
	    				referrer = Lead.where(referral_code: referral_code).first
	    				referrer.update_attributes(referral_count: referrer.referral_count + 1)

	    				mailchimp_referrer = mailchimp.lists.member_info("#{MAILCHIMP_LIST_ID}", [{'email' => referrer.email}])
	    				if mailchimp_referrer['success_count'] == 1
	    					referrer_status = mailchimp_referrer['data'][0]['status']
	    					# Can't update member when Mailchimp is still awaiting this member to confirm their subscription
	    					# It's no big deal because we track referrals via our database
	    					# Could sent reminder email here to the referrer to confirm their subscription since they're clearly
	    					# interested by them referring others.
	    					result = mailchimp.lists.update_member("#{MAILCHIMP_LIST_ID}", {'email' => referrer.email}, {'RCOUNT' => referrer.referral_count}) unless referrer_status == 'pending'
	    				end
	    			rescue => e
	    				errors << {:code => "MC03", :text => "There was a problem updating the referrer at Mailchimp.", :message => e.message, :data => result}
	    			end
	    		end

	    		begin
	    			lead = Lead.where(email: email).first_or_create
	    			lead.update_attributes(name: name)

	    			result = mailchimp.lists.subscribe(
	    				"#{MAILCHIMP_LIST_ID}",
	    				{'email' => email}, {'NAME' => name, 'RCODE' => lead.referral_code, 'RCOUNT' => '0'}, 
	    				"double_optin" => false, 
	    				"send_welcome" => true)

	    		rescue => e
	    			errors << {:message => "There was a problem subscribing you to the list on Mailchimp.", :message => e.message, :data => result}
	    		end
	    	end
	    end
    else # User is in the list
    	# Use referral data from database in the event the user is yet to confirm their subscription
    	# their mailchimp referral data won't be up to date.
    	lead = Lead.where(:email => lead_info['data'][0]['email']).limit(1).pluck(:referral_count, :referral_code).first
    	rcount = lead[0]
    	rcode  = lead[1]
    end

    {:data => {:rcount => rcount, :rcode => rcode}, :errors => errors}
  end

  private

  def downcase_email

  	self.email = email.try(:downcase)

  end

  def set_referral_code

  	self.referral_code = Digest::MD5.hexdigest(email) if email_is_present?

  end

  def email_is_present?

  	!email.blank?

  end

end