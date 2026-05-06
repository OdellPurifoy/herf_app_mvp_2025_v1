# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EventRegistrationConfirmationJob, type: :job do
  let(:registration) { create(:event_registration) }

  describe '#perform' do
    it 'sends a confirmation email' do
      expect do
        described_class.perform_now(registration.id)
      end.to change { ActionMailer::Base.deliveries.count }.by(1)
    end

    it 'does not send if the registration is cancelled' do
      registration.cancel!

      expect do
        described_class.perform_now(registration.id)
      end.not_to(change { ActionMailer::Base.deliveries.count })
    end

    it 'does not raise if the registration does not exist' do
      expect do
        described_class.perform_now('nonexistent-id')
      end.not_to raise_error
    end
  end
end
