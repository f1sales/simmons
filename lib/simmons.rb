# frozen_string_literal: true

require_relative "simmons/version"
require 'f1sales_custom/hooks'
require "f1sales_helpers"

module Simmons
  class Error < StandardError; end
  class F1SalesCustom::Hooks::Lead
    class << self
      def switch_source(lead)
        source_name = lead.source.name

        if source_name.include?('Facebook')
          store_group = parse_facebook_lead(lead).first
        elsif source_name.include?('Widgrid')
          store_group = parse_widgrid_lead(lead).first
        else
          return source_name
        end
        "#{source_name} - #{store_group}"
      end

      def switch_salesman(lead)
        source_name = lead.source.name

        if source_name.include?('Facebook')
          store_name = parse_facebook_lead(lead).last
        elsif source_name.include?('Widgrid')
          store_name = parse_widgrid_lead(lead).last
        else
          return
        end

        { email: "#{emailize(store_name)}@simmons.com.br" }
      end

      def parse_facebook_lead(lead)
        message = lead.message
        (parse_message(message)['conditional_question_3'] || '').split('-')
      end

      def parse_widgrid_lead(lead)
        lead.message.split('-')
      end

      def emailize(string)
        string.dup.force_encoding('UTF-8').unicode_normalize(:nfkd).encode('ASCII', replace: '').downcase.gsub(/\W+/, '')
      end

      def parse_message(message)
        Hash[message.split('; ').map { |s| s.split(': ') }]
      end
    end
  end
end
