require 'rails_helper'

RSpec.describe Lead, :type => :model do
	it { should validate_presence_of :name }
	it { should validate_presence_of :email }

	it { should allow_value('jane@example.com').for(:email) }
	it { should_not allow_value('@example').for(:email) }
	it { should_not allow_value('12345').for(:email) }
	it { should_not allow_value('jane@example').for(:email) }

	it 'should validate case insensitive uniqueness' do
		create(:lead, email: "Email@example.com")
		expect(build(:lead, email: "email@example.com")).to_not be_valid
	end
end 