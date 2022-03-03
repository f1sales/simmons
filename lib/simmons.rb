# frozen_string_literal: true

require_relative "simmons/version"
require 'f1sales_custom/hooks'
require "f1sales_helpers"

module Simmons
  class Error < StandardError; end
  class F1SalesCustom::Hooks::Lead
    class << self
      def switch_source(lead)
        @lead = lead
        source_name = @lead.source.name

        if source_name.include?('Facebook')
          store_group = parse_facebook_lead.first
          handle_integrated_stores(store_group)
        elsif source_name.downcase.include?('widgrid')
          store_group = parse_widgrid_lead(@lead.message).first
          source_name = source_name.split(' - ')[0..1].map(&:capitalize).join(' - ')
          handle_integrated_stores(store_group)
        else
          return source_name
        end
        "#{source_name} - #{store_group}"
      end

      def switch_salesman(lead)
        @lead = lead
        source_name = @lead.source.name

        if source_name.include?('Facebook')
          store_name = parse_facebook_lead.last
        elsif source_name.downcase.include?('widgrid')
          store_name = parse_widgrid_lead(@lead.message).last
        else
          return
        end

        { email: "#{emailize(store_name)}@simmons.com.br" }
      end

      private

      def parse_facebook_lead
        (parse_message(@lead.message)['conditional_question_3'] || '').split('-')
      end

      def parse_widgrid_lead(message)
        message.split(' - ').last.split('-')
      end

      def emailize(string)
        string.dup.force_encoding('UTF-8').unicode_normalize(:nfkd).encode('ASCII', replace: '').downcase.gsub(/\W+/, '')
      end

      def parse_message(message)
        Hash[message.split('; ').map { |s| s.split(': ') }]
      end

      def handle_integrated_stores(store_group)
        integrated_stores = %w[dreamcomfort confortale]
        send("forward_to_#{store_group}") if integrated_stores.include?(store_group)
      end

      def forward_to_dreamcomfort
        create_lead_on('simmonsdreamcomfort', parse_message_to_dreamcomfort(@lead.message))
      end

      def forward_to_confortale
        create_lead_on('confortalecolchoes', @lead.message)
      end

      def create_lead_on(store, message)
        customer = @lead.customer

        response = HTTP.post(
          "https://#{store}.f1sales.org/public/api/v1/leads",
          json: {
            lead: {
              message: message,
              customer: {
                name: customer.name,
                email: customer.email,
                phone: customer.phone
              },
              product: {
                name: @lead.product.name
              },
              transferred_path: {
                from: 'simmons',
                id: @lead.id
              },
              source: {
                name: parse_source(@lead.source.name)
              }
            }
          }
        )

        lead_created = JSON.parse(response.body)

        @lead.update!(transferred_path: { 'to' => store, 'id' => lead_created['data']['id'] })
      end

      def parse_source(source_name)
        splitted_name = source_name.split(' - ')
        if source_name.downcase.include?('widgrid')
          splitted_name.map(&:capitalize)[0..1]
        else
          splitted_name
        end.reverse.join(' - ')
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
