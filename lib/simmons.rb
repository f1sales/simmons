# frozen_string_literal: true

require_relative "simmons/version"
require 'f1sales_custom/hooks'
require "f1sales_helpers"

module Simmons
  class Error < StandardError; end
  class F1SalesCustom::Hooks::Lead
    class << self
      def switch_source(lead)
        store_group, = parse_lead(lead)

        "#{lead.source.name} - #{store_group}"
      end

      def switch_salesman(lead)
        store_group, store_name = parse_lead(lead)
        { email: "#{emailize(store_group)}_#{emailize(store_name)}@simmons.com.br" }
      end

      def parse_lead(lead)
        message = lead.message
        parse_message(message)['loja'].split('-')
      end

      def emailize(string)
        string.gsub(' ', '').downcase
      end

      def parse_message(message)
        Hash[message.split('; ').map { |s| s.split(': ') }]
      end
    end
  end
end
