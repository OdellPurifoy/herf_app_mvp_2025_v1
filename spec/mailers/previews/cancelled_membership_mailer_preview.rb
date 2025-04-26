# frozen_string_literal: true

# Preview all emails at http://localhost:3000/rails/mailers/cancelled_membership_mailer
class CancelledMembershipMailerPreview < ActionMailer::Preview
  def notify
    membership = Membership.first
    CancelledMembershipMailer.with(membership: membership).notify
  end
end
