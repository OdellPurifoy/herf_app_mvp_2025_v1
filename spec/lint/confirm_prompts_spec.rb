# frozen_string_literal: true

require 'rails_helper'

# rails-ujs is not loaded (importmap pins only Turbo and Stimulus), so a bare
# `confirm:` key inside a `data:` hash renders `data-confirm`, which nothing
# handles -- the prompt silently never appears. Turbo's own `data-turbo-confirm`
# is the only confirmation that works here.
#
# This is a source scan, not a view spec, so it lives outside spec/views to keep
# `infer_spec_type_from_file_location!` from loading ActionView::TestCase for it.
RSpec.describe 'Confirmation prompts in source' do
  # Every spelling of the dead rails-ujs key: `confirm:`, `:confirm =>`,
  # `"confirm" =>`/`'confirm' =>`. The negative lookbehind lets `turbo_confirm:`
  # (and any other `*_confirm:` key) through.
  let(:legacy_key_pattern) do
    /(?<!\w)(?:confirm:|:confirm\s*=>|["']confirm["']\s*=>)/
  end

  # The same thing hand-written as a raw HTML attribute.
  let(:raw_attribute_pattern) { /data-confirm\s*=/ }

  let(:destroy_path_helpers) do
    %w[
      destroy_lounge_owner_session_path
      destroy_admin_session_path
      event_path
      membership_path
      special_offer_path
      registration_path
    ]
  end

  # These admin_dashboard "Log Out" buttons have no prompt today. Hardcoded so
  # that a sixth unprompted destructive control -- in a new file or as a second
  # one in these files -- fails instead of silently joining the exemption.
  let(:unprompted_allowlist) do
    %w[
      app/views/admin_dashboard/index.html.erb
      app/views/admin_dashboard/events.html.erb
      app/views/admin_dashboard/lounge_owners.html.erb
      app/views/admin_dashboard/rsvps.html.erb
      app/views/admin_dashboard/special_offers.html.erb
    ]
  end
  let(:expected_unprompted_count) { 5 }

  # Views plus anywhere else that can emit markup.
  let(:scanned_files) do
    Dir[
      Rails.root.join('app/views/**/*.erb'),
      Rails.root.join('app/helpers/**/*.rb'),
      Rails.root.join('app/components/**/*.rb')
    ].sort
  end

  def relative(path)
    pathname = Pathname.new(path)
    pathname.absolute? ? pathname.relative_path_from(Rails.root).to_s : path.to_s
  end

  def line_number_at(contents, offset)
    contents[0...offset].count("\n") + 1
  end

  # Returns the body of each `data: { ... }` hash with its start offset. Brace
  # counting (rather than `[^}]*`) is what lets this see past a nested hash or a
  # `#{}` interpolation sitting before the key.
  def data_hash_bodies(contents)
    contents.to_enum(:scan, /\bdata:\s*\{/).map do
      start = Regexp.last_match.end(0)
      cursor = start
      depth = 1

      while cursor < contents.length && depth.positive?
        case contents[cursor]
        when '{' then depth += 1
        when '}' then depth -= 1
        end
        cursor += 1
      end

      [contents[start...(cursor - 1)].to_s, start]
    end
  end

  def legacy_confirm_offenders(contents, path)
    offenders = data_hash_bodies(contents).flat_map do |body, start|
      body.to_enum(:scan, legacy_key_pattern).map do
        "#{relative(path)}:#{line_number_at(contents, start + Regexp.last_match.begin(0))}"
      end
    end

    offenders + contents.to_enum(:scan, raw_attribute_pattern).map do
      "#{relative(path)}:#{line_number_at(contents, Regexp.last_match.begin(0))}"
    end
  end

  # Each `<%= ... %>` opening tag, which is where a `button_to`'s options live
  # even when it takes a block (`<%= button_to ... do %>`).
  def destructive_button_tags(contents)
    contents.to_enum(:scan, /<%=.*?%>/m).filter_map do
      tag = Regexp.last_match[0]
      offset = Regexp.last_match.begin(0)
      next unless tag.include?('button_to') && tag.match?(/method:\s*:delete/)
      next unless destroy_path_helpers.any? { |helper| tag.include?(helper) }

      [tag, offset]
    end
  end

  describe 'the patterns themselves' do
    it 'matches every spelling of the dead rails-ujs key' do
      aggregate_failures do
        expect('data: { confirm: "Are you sure?" }').to match(legacy_key_pattern)
        expect('data: { :confirm => "Are you sure?" }').to match(legacy_key_pattern)
        expect('data: { "confirm" => "Are you sure?" }').to match(legacy_key_pattern)
        expect(%q{data: { 'confirm' => 'Are you sure?' }}).to match(legacy_key_pattern)
      end
    end

    it 'does not match the working Turbo key or unrelated confirmation fields' do
      aggregate_failures do
        expect('data: { turbo_confirm: "Are you sure?" }').not_to match(legacy_key_pattern)
        expect('f.password_field :password_confirmation').not_to match(legacy_key_pattern)
        expect('data: { password_confirmation: "x" }').not_to match(legacy_key_pattern)
      end
    end

    it 'sees a legacy key sitting behind a nested hash or an interpolation' do
      aggregate_failures do
        expect(legacy_confirm_offenders('data: { turbo: { frame: "x" }, confirm: "y" }', 'a.erb')).not_to be_empty
        expect(legacy_confirm_offenders(%q{data: { id: "row-#{r.id}", confirm: "y" }}, 'a.erb')).not_to be_empty
      end
    end

    it 'flags a raw data-confirm HTML attribute' do
      expect(legacy_confirm_offenders('<button data-confirm="Are you sure?">Go</button>', 'a.erb')).not_to be_empty
    end

    it 'passes a correctly written control' do
      expect(legacy_confirm_offenders('<%= button_to "x", y, data: { turbo_confirm: "Sure?" } %>', 'a.erb')).to be_empty
    end

    it 'recognises a destructive button_to, including the block form' do
      aggregate_failures do
        expect(destructive_button_tags('<%= button_to "D", event_path(e), method: :delete %>')).not_to be_empty
        expect(destructive_button_tags('<%= button_to destroy_admin_session_path, method: :delete do %>')).not_to be_empty
        expect(destructive_button_tags('<%= button_to "Edit", event_path(e) %>')).to be_empty
      end
    end
  end

  describe 'the scanned sources' do
    it 'finds files to scan' do
      expect(scanned_files).not_to be_empty
    end

    it 'declares no bare `confirm:` key in a `data:` hash and no raw data-confirm attribute' do
      offenders = scanned_files.flat_map { |path| legacy_confirm_offenders(File.read(path), path) }

      expect(offenders).to be_empty, lambda {
        "rails-ujs `confirm` never prompts here -- use `data: { turbo_confirm: ... }`.\nFound in:\n" +
          offenders.join("\n")
      }
    end

    it 'gives every destructive button_to a turbo_confirm, outside the known allowlist' do
      unprompted = scanned_files.flat_map do |path|
        contents = File.read(path)

        destructive_button_tags(contents).filter_map do |tag, offset|
          next if tag.include?('turbo_confirm')

          "#{relative(path)}:#{line_number_at(contents, offset)}"
        end
      end

      unexpected = unprompted.reject { |offender| unprompted_allowlist.include?(offender.split(':').first) }

      aggregate_failures do
        expect(unexpected).to be_empty, lambda {
          "Destructive button_to with no confirmation prompt:\n#{unexpected.join("\n")}"
        }
        # Catches a new unprompted control added inside an allowlisted file.
        expect(unprompted.size).to eq(expected_unprompted_count)
      end
    end
  end
end
