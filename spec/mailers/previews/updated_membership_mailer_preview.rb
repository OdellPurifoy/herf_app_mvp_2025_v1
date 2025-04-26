# Preview all emails at http://localhost:3000/rails/mailers/updated_membership_mailer
class UpdatedMembershipMailerPreview < ActionMailer::Preview
  def notify
    membership = Membership.first
    UpdatedMembershipMailer.with(membership: membership).notify
  end
end
