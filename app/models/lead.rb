require 'digest'
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