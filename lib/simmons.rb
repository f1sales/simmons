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
          send_to_dreamcomfort(lead) if store_group == 'dreamcomfort'
        elsif source_name.downcase.include?('widgrid')
          store_group = parse_widgrid_lead(lead).first
          source_name = source_name.split(' - ')[0..1].map(&:capitalize).join(' - ')
          send_to_dreamcomfort(lead) if store_group == 'dreamcomfort'
        else
          return source_name
        end
        "#{source_name} - #{store_group}"
      end

      def switch_salesman(lead)
        source_name = lead.source.name

        if source_name.include?('Facebook')
          store_name = parse_facebook_lead(lead).last
        elsif source_name.downcase.include?('widgrid')
          store_name = parse_widgrid_lead(lead).last
        else
          return
        end

        { email: "#{emailize(store_name)}@simmons.com.br" }
      end

      private

      def parse_facebook_lead(lead)
        message = lead.message
        (parse_message(message)['conditional_question_3'] || '').split('-')
      end

      def parse_widgrid_lead(lead)
        lead.message.split(' - ').last.split('-')
      end

      def emailize(string)
        string.dup.force_encoding('UTF-8').unicode_normalize(:nfkd).encode('ASCII', replace: '').downcase.gsub(/\W+/, '')
      end

      def parse_message(message)
        Hash[message.split('; ').map { |s| s.split(': ') }]
      end

      def send_to_dreamcomfort(lead)
        customer = lead.customer
        source_name = lead.source.name
        source_name = if source_name.downcase.include?('widgrid')
                        source_name.split(' - ').map(&:capitalize)[0..1].reverse.join(' - ')
                      else
                        source_name.split(' - ').reverse.join(' - ')
                      end


        HTTP.post(
          'https://simmonsdreamcomfort.f1sales.org/public/api/v1/leads',
          json: {
            lead: {
              message: parse_message_to_dreamcomfort(lead.message),
              customer: {
                name: customer.name,
                email: customer.email,
                phone: customer.phone
              },
              product: {
                name: lead.product.name
              },
              source: {
                name: source_name
              }
            }
          }
        )
      end

      def parse_message_to_dreamcomfort(message)
        if message.include?('avenida corifeu de azevedo marques 549')
          'av._corifeu_de_azevedo_marques,_549_-_butantã'
        elsif message.include?('avenida ibirapuera 3000')
          'av._ibirapuera,_3000_-_moema'
        elsif message.include?('avenida ibirapuera 2453')
          'av._ibirapuera,_2453_-_moema'
        end
      end
    end
  end
end
