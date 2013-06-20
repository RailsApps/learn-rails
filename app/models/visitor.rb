class Visitor < ActiveRecord::Base
  has_no_table
  column :email, :string
  validates_presence_of :email
  validates_format_of :email, :with => /\A[-a-z0-9_+\.]+\@([-a-z0-9]+\.)+[a-z0-9]{2,4}\z/i

  def subscribe
    mailchimp = Gibbon.new
    result = mailchimp.list_subscribe({
      :id => ENV['MAILCHIMP_LIST_ID'],
      :email_address => self.email,
      :double_optin => false,
      :update_existing => true,
      :send_welcome => true
    })
    Rails.logger.info("Subscribed #{self.email} to MailChimp") if result
  rescue Gibbon::MailChimpError => e
    Rails.logger.info("MailChimp subscribe failed for #{self.email}: " + e.message)
  end

end