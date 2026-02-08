# frozen_string_literal: true

namespace :subscription do
  desc 'Grant free subscription to a lounge owner by email'
  task :grant_free, [:email, :plan] => :environment do |_t, args|
    unless args[:email].present?
      puts 'Usage: rails subscription:grant_free[user@example.com,robusto_monthly]'
      puts 'Plans: robusto_monthly or churchill_monthly'
      exit
    end

    plan = args[:plan] || 'robusto_monthly'
    email = args[:email]

    lounge_owner = LoungeOwner.find_by(email: email)

    unless lounge_owner
      puts "❌ Lounge owner not found with email: #{email}"
      exit
    end

    puts "Found: #{lounge_owner.email} (#{lounge_owner.first_name} #{lounge_owner.last_name})"

    # Create Stripe customer if doesn't exist
    unless lounge_owner.payment_processor
      puts "Creating Stripe customer..."
      lounge_owner.set_payment_processor :stripe
      lounge_owner.payment_processor.update(
        processor_id: "cus_free_#{SecureRandom.hex(8)}"
      )
    end

    customer = lounge_owner.payment_processor

    # Check for existing subscription
    if customer.subscriptions.active.any?
      puts "⚠️  User already has an active subscription:"
      customer.subscriptions.active.each do |sub|
        puts "  - #{sub.name} (#{sub.status})"
      end
      print "Cancel existing and create new? (y/n): "
      response = STDIN.gets.chomp
      
      if response.downcase == 'y'
        customer.subscriptions.active.each(&:cancel)
        puts "✓ Cancelled existing subscriptions"
      else
        puts "Aborting."
        exit
      end
    end

    # Get the price ID
    price_id = if plan == 'churchill_monthly'
                 ENV.fetch('STRIPE_CHURCHILL_MONTHLY_PRICE_ID')
               else
                 ENV.fetch('STRIPE_ROBUSTO_MONTHLY_PRICE_ID')
               end

    puts "Creating free trial subscription for plan: #{plan}"
    puts "Price ID: #{price_id}"

    # Create subscription with trial
    subscription = customer.subscriptions.create!(
      name: plan,
      processor_id: "sub_free_#{SecureRandom.hex(8)}",
      processor_plan: price_id,
      trial_ends_at: 1.year.from_now,
      status: 'active',
      current_period_start: Time.current,
      current_period_end: 1.year.from_now
    )

    puts "\n✅ Free subscription granted!"
    puts "Plan: #{subscription.name}"
    puts "Status: #{subscription.status}"
    puts "Trial ends: #{subscription.trial_ends_at}"
    puts "\nUser can now access all features!"
  end

  desc 'List all lounge owners'
  task list_owners: :environment do
    puts "\n📋 Lounge Owners:\n\n"
    LoungeOwner.all.each do |owner|
      subscription_status = if owner.payment_processor&.subscriptions&.active&.any?
                              "✓ Subscribed (#{owner.payment_processor.subscriptions.active.first.name})"
                            else
                              "✗ No subscription"
                            end
      puts "#{owner.email.ljust(35)} - #{owner.full_name.ljust(25)} - #{subscription_status}"
    end
    puts "\nTotal: #{LoungeOwner.count} owners\n"
  end
end
