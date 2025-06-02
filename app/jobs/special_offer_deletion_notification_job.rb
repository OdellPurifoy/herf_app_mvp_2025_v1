# frozen_string_literal: true

class SpecialOfferDeletionNotificationJob < ApplicationJob
  queue_as :default

  def perform(special_offer_data)
    member_ids = special_offer_data[:member_ids]
    return if member_ids.blank?

    members = Membership.where(id: member_ids)

    return 'No active members found for the lounge' if members.empty?

    members.each do |member|
      next unless member.allow_text_notifications? && !member.opt_out_text_messaging?

      SmsNotificationService.new(to: member.phone_number,
                                 body: deletion_message_for(special_offer_data,
                                                            member)).send_message
    end
  end

  private

  def deletion_message_for(special_offer_data, member)
    <<~SMS
      Hi #{member.first_name},

      We're sorry to inform you that the special offer "#{special_offer_data[:name]}" has been removed.

      Reply HELP for help or STOP to unsubscribe.
    SMS
  end
end
