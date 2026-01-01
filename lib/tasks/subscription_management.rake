# frozen_string_literal: true

namespace :subscription do
  desc 'Start a free trial for a lounge owner'
  task :start_trial, %i[email days] => :environment do |_t, args|
    if args[:email].blank?
      puts '❌ ERROR: Email is required'
      puts ''
      puts 'Usage: rails subscription:start_trial[email@example.com,30]'
      puts 'Default trial period is 14 days if not specified'
      exit 1
    end

    trial_days = (args[:days] || 14).to_i

    lounge_owner = LoungeOwner.find_by(email: args[:email])

    unless lounge_owner
      puts "❌ ERROR: Lounge owner not found with email: #{args[:email]}"
      exit 1
    end

    puts "🎯 Starting #{trial_days}-day free trial for: #{lounge_owner.email}"
    puts ''

    # Choose which plan for the trial (default to Robusto)
    plan_id = ENV.fetch('STRIPE_ROBUSTO_MONTHLY_PRICE_ID')

    begin
      # Create a trial subscription
      subscription = lounge_owner.payment_processor.subscribe(
        name: 'robusto_monthly',
        plan: plan_id,
        trial_period_days: trial_days
      )

      puts '✅ SUCCESS! Free trial started'
      puts ''
      puts "Owner: #{lounge_owner.full_name} (#{lounge_owner.email})"
      puts 'Plan: Robusto Monthly'
      puts "Trial Days: #{trial_days}"
      puts "Trial Ends: #{subscription.trial_ends_at.strftime('%B %d, %Y')}"
      puts "Status: #{subscription.status}"
      puts ''
      puts 'The subscription will automatically convert to paid after the trial ends'
      puts "unless cancelled before: #{subscription.trial_ends_at.strftime('%B %d, %Y')}"
    rescue StandardError => e
      puts '❌ FAILED! Could not start trial'
      puts "Error: #{e.message}"
      puts ''
      puts 'Common issues:'
      puts '1. Lounge owner already has an active subscription'
      puts '2. Invalid Stripe price ID'
      puts '3. Stripe API key not configured'
    end
  end

  desc 'Cancel a subscription'
  task :cancel, [:email] => :environment do |_t, args|
    if args[:email].blank?
      puts '❌ ERROR: Email is required'
      puts ''
      puts 'Usage: rails subscription:cancel[email@example.com]'
      exit 1
    end

    lounge_owner = LoungeOwner.find_by(email: args[:email])

    unless lounge_owner
      puts "❌ ERROR: Lounge owner not found with email: #{args[:email]}"
      exit 1
    end

    subscription = lounge_owner.active_subscription

    unless subscription
      puts "❌ ERROR: No active subscription found for: #{args[:email]}"
      exit 1
    end

    puts "Cancelling subscription for: #{lounge_owner.email}"

    begin
      subscription.cancel

      puts '✅ SUCCESS! Subscription cancelled'
      puts ''
      puts "Owner: #{lounge_owner.full_name} (#{lounge_owner.email})"
      puts "Status: #{subscription.status}"
    rescue StandardError => e
      puts '❌ FAILED! Could not cancel subscription'
      puts "Error: #{e.message}"
    end
  end

  desc 'Check subscription status'
  task :status, [:email] => :environment do |_t, args|
    if args[:email].blank?
      puts '❌ ERROR: Email is required'
      puts ''
      puts 'Usage: rails subscription:status[email@example.com]'
      exit 1
    end

    lounge_owner = LoungeOwner.find_by(email: args[:email])

    unless lounge_owner
      puts "❌ ERROR: Lounge owner not found with email: #{args[:email]}"
      exit 1
    end

    puts "📊 Subscription Status for: #{lounge_owner.full_name}"
    puts '=' * 60
    puts ''
    puts "Email: #{lounge_owner.email}"
    puts "Subscribed: #{lounge_owner.subscribed? ? '✅ Yes' : '❌ No'}"

    if lounge_owner.subscribed?
      subscription = lounge_owner.active_subscription
      puts "Plan: #{subscription.name}"
      puts "Status: #{subscription.status}"
      puts "Processor ID: #{subscription.processor_id}"

      if subscription.on_trial?
        puts 'On Trial: ✅ Yes'
        puts "Trial Ends: #{subscription.trial_ends_at.strftime('%B %d, %Y at %I:%M %p')}"
      else
        puts 'On Trial: ❌ No'
      end

      puts "Ends At: #{subscription.ends_at.strftime('%B %d, %Y at %I:%M %p')}" if subscription.ends_at
    else
      puts ''
      puts 'No active subscription found.'
      puts ''
      puts 'To start a free trial, run:'
      puts "rails subscription:start_trial[#{args[:email]},14]"
    end
  end

  desc 'List all subscriptions'
  task list: :environment do
    subscriptions = Pay::Subscription.all.includes(:customer)

    puts "📋 All Subscriptions (#{subscriptions.count})"
    puts '=' * 80
    puts ''

    if subscriptions.empty?
      puts 'No subscriptions found.'
    else
      subscriptions.each do |sub|
        owner = sub.customer.owner
        puts "Owner: #{owner.full_name} (#{owner.email})"
        puts "  Plan: #{sub.name}"
        puts "  Status: #{sub.status}"
        puts "  Trial: #{sub.on_trial? ? "Yes (ends #{sub.trial_ends_at.strftime('%m/%d/%Y')})" : 'No'}"
        puts "  Created: #{sub.created_at.strftime('%B %d, %Y')}"
        puts ''
      end
    end
  end
end
