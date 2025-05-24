# frozen_string_literal: true

class SpecialOfferNotificationService
  def initialize(special_offer)
    @special_offer = special_offer
    @lounge = special_offer.lounge
  end

  def notify_members
    eligible_members.each do |member|
      next unless member.allow_text_notifications? && !member.opt_out_text_messaging?

      message_body = build_message
      SmsNotificationService.new(to: member.phone_number, body: message_body).send_message
    end
  end

  private

  def eligible_members
    @lounge.memberships.active
  end

  def build_message
    message = "#{@lounge.name} has a new offer: #{@special_offer.name} "
    message += "valid from #{@special_offer.start_date.strftime('%m/%d/%Y')} to #{@special_offer.end_date.strftime('%m/%d/%Y')}. "
    message += @special_offer.description.to_s if @special_offer.description.present?
    message += ' This is a members-only offer.' if @special_offer.members_only?
    message += " Use code: #{@special_offer.offer_code}" if @special_offer.offer_code.present?
    message
  end
end
