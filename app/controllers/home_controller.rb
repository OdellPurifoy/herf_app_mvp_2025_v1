# frozen_string_literal: true

class HomeController < ApplicationController
  def index
    faqs_file = Rails.root.join('config', 'faqs.yml')
    @faqs = YAML.load_file(faqs_file)['faqs']
  end
end
