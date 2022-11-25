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
        if message_down.include?('av corifeu de azevedo marques, 549')
          'av._corifeu_de_azevedo_marques,_549_-_butantã'
        elsif message_down.include?('av ibirapuera, 3000')
          'av._ibirapuera,_3000_-_moema'
        elsif message_down.include?('av ibirapuera, 2453')
          'av._ibirapuera,_2453_-_moema'
        elsif message_down.include?('av braz leme, 757')
          'av._braz_leme,_757_-_santana'
        end
      end
    end
  end
end

# lead.customer
# #<Customer _id: 6377be8c810ac5ffb8de1d9f, created_at: 2022-11-18 17:19:08 UTC, updated_at: 2022-11-23 14:20:32 UTC, name: "Columbus Perfolius", email: "e_malkav@hotmail.com", phone: "11943191729", cpf: "", salesman_id: nil, version: nil, modifier_id: nil>
# (byebug) lead.source
# #<Source _id: 637fa6d8810ac51f035349da, name: "", supported: true, team_id: nil, integration_id: BSON::ObjectId('637fa6d8810ac51f035349d9')>
# (byebug) lead.source.integration
# #<Integrations::Spreadsheet _id: 637fa6d8810ac51f035349d9, reference: nil, name: "Decor American", working: true, repeat_in: 5, error_message: "", _type: "Integrations::Spreadsheet"> nil, version: nil, modifier_id: nil>
# # lead.source
# # #<Source _id: 637bc978810ac5a4f8edd3ae, name: "", supported: true, team_id: nil, integration_id: BSON::ObjectId('637bc978810ac5a4f8edd3ad')>
# # lead.source.integration
# # #<Integrations::Spreadsheet _id: 637bc978810ac5a4f8edd3ad, reference: nil, name: "Decor American", working: true, repeat_in: 5, error_message: "", _type: "Integrations::Spreadsheet">


# # # Nº 2

# # lead.customer
# # #<Customer _id: 6377be8d810ac5ffb8de1da5, created_at: 2022-11-18 17:19:09 UTC, updated_at: 2022-11-21 18:43:26 UTC, name: "Claudia", email: "clauvfvidoi@gmail.com", phone: "11953009516", cpf: "", salesman_id: nil, version: nil, modifier_id: nil>
# # lead.source
# # #<Source _id: 637bc978810ac5a4f8edd3ae, name: "", supported: true, team_id: nil, integration_id: BSON::ObjectId('637bc978810ac5a4f8edd3ad')>
# # lead.source.integration
# # nil





# self
# #<Lead _id: 637fada3810ac5386f3cabc9, created_at: 2022-11-24 17:45:07 UTC, updated_at: 2022-11-24 17:45:07 UTC, description: "", message: nil, expire_time: nil, interaction: "pending", notified_salesman: [], attachments: [], notified_time: nil, observation: "", admin_observation: "", reply_time: nil, latest_reminder_time: nil, sold_date: nil, phonecall: false, transfered_by: nil, transferred_path: {}, transferred_team: nil, manually_inserted: false, contact_form_cd: nil, inbound_channel_cd: 0, product_id: BSON::ObjectId('602e87a7810ac58d373f34da'), source_id: BSON::ObjectId('637fada3810ac5386f3cabc8'), customer_id: BSON::ObjectId('6377be8c810ac5ffb8de1d9f'), salesman_id: nil, discard_reason_id: nil, removed_reason_cd: nil, temperature_cd: nil, version: nil, modifier_id: nil>
# (byebug) self.customer
# #<Customer _id: 6377be8c810ac5ffb8de1d9f, created_at: 2022-11-18 17:19:08 UTC, updated_at: 2022-11-24 17:17:19 UTC, name: "Columbus Perfolius", email: "e_malkav@hotmail.com", phone: "11943191729", cpf: "", salesman_id: nil, version: nil, modifier_id: nil>

# (byebug) self.source
# #<Source _id: 637fada3810ac5386f3cabc8, name: "", supported: true, team_id: nil, integration_id: BSON::ObjectId('637fada3810ac5386f3cabc7')>
# (byebug) self.source.integration
# #<Integrations::Spreadsheet _id: 637fada3810ac5386f3cabc7, reference: nil, name: "Decor American", working: true, repeat_in: 5, error_message: "", _type: "Integrations::Spreadsheet">
# (byebug) MONGODB | localhost:27017 req:16 conn:1:1 sconn:35 | ornare_prod_dump.find | STARTED | {"find"=>"sources", "filter"=>{"name"=>"Planilha - Decor American - "}, "sort"=>{"_id"=>1}, "limit"=>1, "singleBatch"=>true, "$db"=>"ornare_prod_dump", "lsid"=>{"id"=><BSON::Binary:0x47398834147000 type=uuid data=0x346f4390c5714b37...>}}




# (byebug) self.customer
# #<Customer _id: 6377be8c810ac5ffb8de1d9f, created_at: 2022-11-18 17:19:08 UTC, updated_at: 2022-11-24 17:45:40 UTC, name: "Columbus Perfolius", email: "e_malkav@hotmail.com", phone: "11943191729", cpf: "", salesman_id: nil, version: nil, modifier_id: nil>
# (byebug) self.source
# #<Source _id: 637fada3810ac5386f3cabc8, name: "", supported: true, team_id: nil, integration_id: BSON::ObjectId('637fada3810ac5386f3cabc7')>
# (byebug) self.source.integration
# MONGODB | localhost:27017 req:29 conn:1:1 sconn:35 | ornare_prod_dump.find | STARTED | {"find"=>"integrations", "filter"=>{"_id"=>BSON::ObjectId('637fada3810ac5386f3cabc7')}, "limit"=>1, "singleBatch"=>true, "$db"=>"ornare_prod_dump", "lsid"=>{"id"=><BSON::Binary:0x47398834147000 type=uuid data=0x346f4390c5714b37...>}}
# MONGODB | localhost:27017 req:29 | ornare_prod_dump.find | SUCCEEDED | 0.096s
# nil
# (byebug) self.source.integration
# nil










# (byebug) self.customer
# #<Customer _id: 6377be8c810ac5ffb8de1d9f, created_at: 2022-11-18 17:19:08 UTC, updated_at: 2022-11-24 17:48:01 UTC, name: "Columbus Perfolius", email: "e_malkav@hotmail.com", phone: "11943191729", cpf: "", salesman_id: nil, version: nil, modifier_id: nil>
# (byebug) self.source
# #<Source _id: 637fafb5810ac54173621746, name: "", supported: true, team_id: nil, integration_id: BSON::ObjectId('637fafb5810ac54173621745')>
# (byebug) self.source.integration
# #<Integrations::Spreadsheet _id: 637fafb5810ac54173621745, reference: nil, name: "Decor American", working: true, repeat_in: 5, error_message: "", _type: "Integrations::Spreadsheet">
# (byebug) continue




# (byebug) self.customer
# #<Customer _id: 6377be8c810ac5ffb8de1d9f, created_at: 2022-11-18 17:19:08 UTC, updated_at: 2022-11-24 17:54:35 UTC, name: "Columbus Perfolius", email: "e_malkav@hotmail.com", phone: "11943191729", cpf: "", salesman_id: nil, version: nil, modifier_id: nil>
# (byebug) self.source
# #<Source _id: 637fafb5810ac54173621746, name: "", supported: true, team_id: nil, integration_id: BSON::ObjectId('637fafb5810ac54173621745')>
# (byebug) self.source.integration
# MONGODB | localhost:27017 req:27 conn:1:1 sconn:42 | ornare_prod_dump.find | STARTED | {"find"=>"integrations", "filter"=>{"_id"=>BSON::ObjectId('637fafb5810ac54173621745')}, "limit"=>1, "singleBatch"=>true, "$db"=>"ornare_prod_dump", "lsid"=>{"id"=><BSON::Binary:0x46937742025340 type=uuid data=0x9c11313474b04bbb...>}}
# MONGODB | localhost:27017 req:27 | ornare_prod_dump.find | SUCCEEDED | 0.039s
# nil


# [BSON::ObjectId('6074895e810ac5fffc1420a0'), BSON::ObjectId('607489a3810ac5fffc1420a1'), BSON::ObjectId('607489ab810ac5fffc1420a2'), BSON::ObjectId('607489b3810ac5fffc1420a3'), BSON::ObjectId('607489b4810ac5fffc1420a5'), BSON::ObjectId('607489cd810ac5fffc1420a6'), BSON::ObjectId('607489dd810ac50460c5b0c6'), BSON::ObjectId('607489f6810ac505b38ad959'), BSON::ObjectId('60748a3f810ac505b38ad95b'), BSON::ObjectId('60748aba810ac507e30039f6'), BSON::ObjectId('6076ea45810ac538123f38d0'), BSON::ObjectId('60c8be11810ac5a1624ca5e9'), BSON::ObjectId('60d10622810ac514f1bafa03'), BSON::ObjectId('60f88a6b810ac5bb6fae3826'), BSON::ObjectId('61154617810ac5da88575ca4'), BSON::ObjectId('611bce26810ac501350eb57c'), BSON::ObjectId('611bd63e810ac52100042c2b'), BSON::ObjectId('611ec11e810ac57d3b09071e'), BSON::ObjectId('6130d417810ac5b8c247dcd1'), BSON::ObjectId('617ae371810ac52bb8d5dd1c'), BSON::ObjectId('627bf6ce810ac55ee3f9e995'), BSON::ObjectId('6377be8c810ac5ffb8de1da0'), BSON::ObjectId('6377bebd810ac5ffb8de1db8'), BSON::ObjectId('637bb7b3810ac561cab84459'), BSON::ObjectId('637bb937810ac561cab84472'), BSON::ObjectId('637bc3c3810ac58e6863032c'), BSON::ObjectId('637bc58a810ac59663022e4e'), BSON::ObjectId('637bc6ce810ac59c37b79892')] 
# 2.6.6 :006 > 
