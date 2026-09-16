# frozen_string_literal: true

require 'ostruct'

class EventDeletionEmailNotificationJob < ApplicationJob
  queue_as :default

  def perform(event_data)
    return if event_data[:member_ids].blank?

    event = OpenStruct.new(
      name: event_data[:name],
      date: event_data[:date],
      start_time: event_data[:start_time],
      lounge: OpenStruct.new(
        name: event_data[:lounge_name],
        email: event_data[:lounge_email],
        phone_number: event_data[:lounge_phone_number]
      )
    )

    Membership.where(id: event_data[:member_ids]).find_each do |member|
      next unless member.allow_email_notifications?

      # deliver_now: the OpenStruct stand-in for the destroyed event can't be serialized by deliver_later.
      CancelledEventMailer.with(member: member, event: event).notify.deliver_now
    end
  end
end
