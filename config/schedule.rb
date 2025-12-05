# frozen_string_literal: true

# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
# set :output, "/path/to/my/cron_log.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever

# Set environment variables
set :environment, 'production'

case @environment
when 'development'
  set :output, "#{path}/log/cron_development.log"
when 'production'
  set :output, "#{path}/log/cron.log"
end

# Send one week reminders every day at 9 AM
every 1.day, at: '9:00 am' do
  runner 'OneWeekEventReminderJob.perform_later'
end

# Send one day reminders every day at 6 PM
every 1.day, at: '6:00 pm' do
  runner 'OneDayEventReminderJob.perform_later'
end
