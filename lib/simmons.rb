# frozen_string_literal: true

require_relative 'simmons/version'
require 'f1sales_custom/hooks'
require 'f1sales_helpers'
require 'json'

module Simmons
  class Error < StandardError; end

  class F1SalesCustom::Hooks::Lead
    class << self
      def switch_source(lead)
        @lead = lead
        @source_name = @lead.source.name

        if @source_name['Facebook'] || source_name_down['widgrid'] || source_name_down['lead de empresas']
          source_name_and_store_group_for_switch_source
          "#{@source_name} - #{@store_group}"
        elsif @source_name['Planilha']
          @source_name
        else
          "#{@source_name} - #{lead_message}"
        end
      end

      def switch_salesman(lead)
        @lead = lead
        @source_name = @lead.source.name

        return unless @source_name['Facebook'] || source_name_down['widgrid'] || source_name_down['lead de empresas']
        return if lead_message_down['sem loja']

        store_name = store_name_for_switch_salesman
        store_name = 'av ibirapuera 2453' if store_name.downcase['av ibirapuera']

        { email: "#{emailize(store_name)}@simmons.com.br" }
      end

      private

      def source_name_down
        @source_name.downcase
      end

      def source_name_and_store_group_for_switch_source
        if @source_name['Facebook']
          store_group_for_facebook
        elsif source_name_down['widgrid'] || source_name_down['lead de']
          store_group_and_source_name_for_widgrid
        end
      end

      def lead_message
        @lead.message
      end

      def lead_message_down
        lead_message.downcase
      end

      def store_group_for_facebook
        @store_group = parse_facebook_lead.last
        handle_integrated_stores(@store_group)
      end

      def store_group_and_source_name_for_widgrid
        @source_name = @source_name.split(' - ')[0..1].map(&:capitalize).join(' - ')
        return @store_group = @lead.description if lead_message_down == 'sem loja'

        @store_group = parse_widgrid_lead(lead_message).last
        handle_integrated_stores(@store_group)
      end

      def store_name_for_switch_salesman
        if @source_name['Facebook']
          parse_facebook_lead[1]
        elsif @source_name.downcase['widgrid'] || source_name_down['lead de']
          parse_widgrid_lead(lead_message)[1]
        end
      end

      def parse_facebook_lead
        (parse_message(lead_message)['conditional_question_3'] || '').split(' - ')
      end

      def parse_widgrid_lead(message)
        message.split(' - ')[2..]
      end

      def emailize(string)
        string.dup.force_encoding('UTF-8').unicode_normalize(:nfkd).encode('ASCII', replace: '').downcase.gsub(/\W+/,
                                                                                                               '')
      end

      def parse_message(message)
        Hash[message.split('; ').map { |s| s.split(': ') }]
      end

      def handle_integrated_stores(store_group)
        store_group_down = store_group.downcase.gsub(' ', '')
        integrated_stores = %w[dreamcomfort dreamconfort confortale mega]
        send("forward_to_#{store_group_down}") if integrated_stores.include?(store_group_down)
      end

      def forward_to_dreamcomfort
        create_lead_on('simmonsdreamcomfort', parse_message_to_dreamcomfort(lead_message))
      end

      def forward_to_confortale
        create_lead_on('confortalecolchoes', lead_message)
      end

      def forward_to_mega
        create_lead_on('megacolchoes', lead_message)
      end

      def forward_to_dreamconfort
        create_lead_on('simmonsdreamcomfort', parse_message_to_dreamcomfort(lead_message))
      end

      def create_lead_on(store, message)
        response = HTTP.post("https://#{store}.f1sales.org/public/api/v1/leads", json: lead_payload(message))

        JSON.parse(response.body)
      end

      def customer
        @lead.customer
      end

      def lead_payload(message)
        {
          lead: {
            message: message,
            customer: customer_data,
            product: product_name,
            transferred_path: transferred_path,
            source: source_name
          }
        }
      end

      def customer_data
        {
          name: customer.name,
          email: customer.email,
          phone: customer.phone
        }
      end

      def product_name
        {
          name: @lead.product.name
        }
      end

      def source_name
        {
          name: parse_source(@lead.source.name)
        }
      end

      def transferred_path
        {
          from: 'simmons',
          id: @lead.id.to_s
        }
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
        message_down = message.downcase
        if message_down.include?('av corifeu de azevedo marques, 547')
          'av._corifeu_de_azevedo_marques,_547_-_butantã'
        elsif message_down.include?('av ibirapuera, 3399')
          'av._ibirapuera,_3399_-_moema'
        elsif message_down.include?('av ibirapuera, 3000')
          'av._ibirapuera,_3000_-_moema'
        elsif message_down.include?('av ibirapuera, 2453')
          'av._ibirapuera,_2453_-_moema'
        elsif message_down.include?('braz leme, 757')
          'av._braz_leme,_757_-_santana'
        elsif message_down.include?('av sumare, 1101')
          'perdizes_-_av_sumare,_1101_- dream_comfort'
        end
      end
    end
  end
end
