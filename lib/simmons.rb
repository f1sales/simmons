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

        return face_wid_le_source if face_wid_le?

        if @source_name['Planilha']
          @source_name
        else
          source_name_swith_source(lead_message)
        end
      end

      def switch_salesman(lead)
        @lead = lead
        @source_name = @lead.source.name

        return unless face_wid_le?
        return if lead_message_down['sem loja']

        store_name = store_name_for_switch_salesman || ''
        return if store_name.empty?

        { email: "#{emailize(store_name)}@simmons.com.br" }
      end

      private

      def face_wid_le?
        @source_name['Facebook'] || source_name_down['widgrid'] || source_name_down['lead de empresas']
      end

      def face_wid_le_source
        source_name_and_store_group_for_switch_source
        return "#{source_name_swith_source} - Exclusivo" if exclusive?

        source_name_swith_source
      end

      def exclusive?
        from_simmons_dreamcomfort? || from_simmons_better_sleep?
      end

      def from_simmons_dreamcomfort?
        source_name_swith_source[/Simmons - Dream ?Co[mn]fort/]
      end

      def from_simmons_better_sleep?
        source_name_swith_source['Simmons - Better Sleep']
      end

      def source_name_swith_source(message = @store_group)
        message.empty? ? @source_name : "#{@source_name} - #{message}"
      end

      def source_name_down
        @source_name.downcase
      end

      def source_name_and_store_group_for_switch_source
        if lead_message_down['simmons concierge']
          @store_group = 'Simmons Concierge'
        elsif @source_name['Facebook']
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
        @store_group = parse_facebook_lead.last || ''
        handle_integrated_stores(@store_group)
      end

      def store_group_and_source_name_for_widgrid
        @source_name = @source_name.split(' - ')[0..1].map(&:capitalize).join(' - ')
        return @store_group = 'Concierge' if lead_message_down == 'sem loja'

        @store_group = parse_widgrid_lead(lead_message)&.last || ''
        handle_integrated_stores(@store_group)
      end

      def store_name_for_switch_salesman
        if lead_message_down['simmons concierge']
          'Simmons Concierge'
        elsif @source_name['Facebook']
          parse_facebook_lead[1]
        elsif @source_name.downcase['widgrid'] || source_name_down['lead de']
          parse_widgrid_lead(lead_message)[1] || ''
        end
      end

      def parse_facebook_lead
        (parse_message(lead_message)['conditional_question_3'] || '').split(' - ')
      end

      def parse_widgrid_lead(message)
        message.split(' - ')[2..] || []
      end

      def emailize(string)
        string.dup.force_encoding('UTF-8').unicode_normalize(:nfkd).encode('ASCII', replace: '').downcase.gsub(/\W+/,
                                                                                                               '')
      end

      def parse_message(message)
        Hash[message.split('; ').map { |s| s.split(': ') }]
      end

      def handle_integrated_stores(store_group)
        store_group_down = emailize(store_group)
        return if store_group_down['mocbettersleep']

        store_group_down = 'bettersleep' if store_group_down['bettersleep']
        integrated_stores = %w[dreamconfort bettersleep mattressone dreamcomfortcolchoes]
        return unless integrated_stores.include?(store_group_down)

        send("forward_to_#{store_group_down}")

        @lead.interaction = :contacted
      end

      def forward_to_bettersleep
        create_lead_on('bettersleepcolchoes', lead_message)
      end

      def forward_to_mattressone
        create_lead_on('ortoluxo', lead_message)
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
            description: @store_group,
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
        source_return = if source_name.downcase['widgrid']
                          splitted_name.map(&:capitalize)[0..1]
                        else
                          splitted_name
                        end.reverse.join(' - ')

        return "#{source_return} - Dream Comfort - Exclusivo" if from_simmons_dreamcomfort?

        source_return
      end
    end
  end
end
