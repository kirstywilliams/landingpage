FactoryGirl.define do

	factory :lead do

		name "Jane"
		sequence(:email) { |n| "test#{n}@email.com" }
		referral_count 0
		referral_code Digest::MD5.hexdigest('123456')

	end
end
