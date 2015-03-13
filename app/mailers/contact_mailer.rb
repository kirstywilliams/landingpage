class ContactMailer < ActionMailer::Base
  def send_email(user_info)
    @user_info = user_info

    mail(
      to: "<%= CONTACT_EMAIL %>",
      subject: "<%= COMPANY_NAME %> Contact Form",
      from: "#{@user_info["email"]}"
    )
  end
end