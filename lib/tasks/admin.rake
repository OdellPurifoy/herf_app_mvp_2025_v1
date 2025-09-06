# frozen_string_literal: true

namespace :admin do
  desc 'Create a new admin user'
  task :create, %i[email password] => :environment do |_t, args|
    email = args[:email] || ask_for('Email')
    password = args[:password] || ask_for('Password', true)

    admin = Admin.new(email: email, password: password, password_confirmation: password)

    if admin.save
      puts "✅ Admin user created successfully: #{admin.email}"
    else
      puts '❌ Failed to create admin user:'
      admin.errors.full_messages.each { |message| puts "  - #{message}" }
    end
  end

  def ask_for(field, is_password = false)
    puts "Please enter the admin's #{field.downcase}:"
    if is_password
      begin
        system('stty -echo')
        password = $stdin.gets.chomp
        puts "\n"
      ensure
        system('stty echo')
      end
      password
    else
      $stdin.gets.chomp
    end
  end
end
