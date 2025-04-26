# frozen_string_literal: true

# Preview all emails at http://localhost:3000/rails/mailers/new_membership_mailer
class NewMembershipMailerPreview < ActionMailer::Preview
  def notify
    membership = Membership.first
    NewMembershipMailer.with(membership: membership).notify
  end
end
