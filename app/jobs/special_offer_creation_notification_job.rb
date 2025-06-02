# frozen_string_literal: true

class SpecialOfferCreationNotificationJob < ApplicationJob
  queue_as :default

  def perform(special_offer_id)
    begin
      special_offer = SpecialOffer.find(special_offer_id)
    rescue ActiveRecord::RecordNotFound
      puts 'Special Offer Not Found'
      return
    end

    members = special_offer.lounge.memberships.active

    return 'No active members found for the lounge' if members.empty?

    members.each do |member|
      next unless member.allow_text_notifications? && !member.opt_out_text_messaging?

      SmsNotificationService.new(to: member.phone_number,
                                 body: creation_message_for(special_offer,
                                                            member)).send_message
    end
  end

  private

  def creation_message_for(special_offer, member)
    <<~SMS
      Hi #{member.first_name},
      #{special_offer.lounge.name} has a new special offer for you!
      "#{special_offer.name}"
      Offer Type: #{special_offer.offer_type}
      Start Date: #{special_offer.start_date.strftime('%B %d, %Y')}
      End Date: #{special_offer.end_date.strftime('%B %d, %Y')}

      Description:
      #{special_offer.description&.truncate(160)}

      Reply HELP for help or STOP to unsubscribe.
    SMS
  end
end
