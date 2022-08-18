require File.expand_path 'spec_helper.rb', __dir__
require 'ostruct'
require 'byebug'

RSpec.describe F1SalesCustom::Hooks::Lead do
  let(:lead_id) { 'abc123' }
  let(:lead_created_payload) do
    {
      'data' => {
        'id' => 'newleadabc123'
      }
    }
  end

  let(:switch_source) { described_class.switch_source(lead) }

  let(:switch_salesman) { described_class.switch_salesman(lead) }

  context 'when came from facebook' do
    let(:lead) do
      lead = OpenStruct.new
      lead.source = source
      lead.message = 'conditional_question_1: Belo Horizonte; conditional_question_2: Belvedere; conditional_question_3: arte do sono-avenida luiz paulo franco 981'
      lead.id = lead_id

      lead
    end

    let(:source) do
      source = OpenStruct.new
      source.name = 'Facebook - Simmons'
      source
    end

    context 'when has store group' do
      it 'returns source name' do
        expect(switch_source).to eq('Facebook - Simmons - arte do sono')
      end

      it 'returns salesman email' do
        expect(switch_salesman).to eq({ email: 'avenidaluizpaulofranco981@simmons.com.br' })
      end
    end
  end

  context 'when came from widgrid' do
    let(:lead) do
      lead = OpenStruct.new
      lead.source = source
      lead.message = 'Simmons - ESC - grupo alfa-avenida nossa senhora de fatima 258'
      lead.id = lead_id

      lead
    end

    let(:source) do
      source = OpenStruct.new
      source.name = 'WIDGRID - SIMMONS - ENCONTRE SEU COLCHÃO'
      source
    end

    context 'when has store group' do
      it 'returns source name' do
        expect(switch_source).to eq('Widgrid - Simmons - grupo alfa')
      end

      it 'returns salesman email' do
        expect(switch_salesman).to eq({ email: 'avenidanossasenhoradefatima258@simmons.com.br' })
      end
    end
  end

  context 'when is to megacolchoes' do
    let(:source) do
      source = OpenStruct.new
      source.name = source_name
      source
    end

    let(:customer) do
      customer = OpenStruct.new
      customer.name = 'Marcio'
      customer.phone = '1198788899'
      customer.email = 'marcio@f1sales.com.br'

      customer
    end

    let(:product) do
      product = OpenStruct.new
      product.name = 'São Paulo - BF - novo formulario'

      product
    end

    let(:lead) do
      lead = OpenStruct.new
      lead.message = message
      lead.source = source
      lead.product = product
      lead.customer = customer
      lead.id = lead_id

      lead
    end

    let(:call_url) { 'https://megacolchoes.f1sales.org/public/api/v1/leads' }

    before do
      stub_request(:post, call_url)
        .with(body: lead_payload.to_json).to_return(status: 200, body: lead_created_payload.to_json, headers: {})
    end

    context 'when source is from facebook' do
      let(:source_name) { 'Facebook - Simmons' }
      let(:message) do
        'conditional_question_1: São Paulo; conditional_question_2: São Paulo; conditional_question_3: mega-alameda nhambiquaras 801'
      end

      let(:lead_payload) do
        {
          lead: {
            message: message,
            customer: {
              name: customer.name,
              email: customer.email,
              phone: customer.phone
            },
            product: {
              name: product.name
            },
            transferred_path: {
              from: 'simmons',
              id: lead_id
            },
            source: {
              name: 'Simmons - Facebook'
            }
          }
        }
      end

      it 'returns source name' do
        expect(switch_source).to eq('Facebook - Simmons - mega')
      end

      it 'post to mega colchoes' do
        begin
          switch_source
        rescue StandardError
          nil
        end

        expect(WebMock).to have_requested(:post, call_url).with(body: lead_payload)
      end
    end
  end

  context 'when is to simmons dream comfort' do
    let(:source) do
      source = OpenStruct.new
      source.name = source_name
      source
    end

    let(:customer) do
      customer = OpenStruct.new
      customer.name = 'Marcio'
      customer.phone = '1198788899'
      customer.email = 'marcio@f1sales.com.br'

      customer
    end

    let(:product) do
      product = OpenStruct.new
      product.name = 'São Paulo - BF - novo formulario'

      product
    end

    let(:lead) do
      lead = OpenStruct.new
      lead.message = message
      lead.source = source
      lead.product = product
      lead.customer = customer
      lead.id = lead_id

      lead
    end

    let(:call_url) { 'https://simmonsdreamcomfort.f1sales.org/public/api/v1/leads' }

    before do
      stub_request(:post, call_url)
        .with(body: lead_payload.to_json).to_return(status: 200, body: lead_created_payload.to_json, headers: {})
    end

    context 'when source is from facebook' do
      let(:source_name) { 'Facebook - Simmons' }
      let(:message) do
        'conditional_question_1: São Paulo; conditional_question_2: Butantã; conditional_question_3: dreamcomfort-avenida corifeu de azevedo marques 549'
      end

      let(:lead_payload) do
        {
          lead: {
            message: 'av._corifeu_de_azevedo_marques,_549_-_butantã',
            customer: {
              name: customer.name,
              email: customer.email,
              phone: customer.phone
            },
            product: {
              name: product.name
            },
            transferred_path: {
              from: 'simmons',
              id: lead_id
            },
            source: {
              name: 'Simmons - Facebook'
            }
          }
        }
      end

      it 'returns source name' do
        expect(switch_source).to eq('Facebook - Simmons - dreamcomfort')
      end

      it 'post to simmons dream comfort' do
        begin
          switch_source
        rescue StandardError
          nil
        end

        expect(WebMock).to have_requested(:post, call_url).with(body: lead_payload)
      end
    end

    context 'when source is from widgrid' do
      let(:source_name) { 'WIDGRID - SIMMONS - ENCONTRE SEU COLCHÃO' }
      let(:message) { 'Simmons - ESC - dreamcomfort-avenida ibirapuera 3000' }
      let(:lead_payload) do
        {
          lead: {
            message: 'av._ibirapuera,_3000_-_moema',
            customer: {
              name: customer.name,
              email: customer.email,
              phone: customer.phone
            },
            product: {
              name: product.name
            },
            transferred_path: {
              from: 'simmons',
              id: lead_id
            },
            source: {
              name: 'Simmons - Widgrid'
            }
          }
        }
      end

      it 'returns source name' do
        expect(switch_source).to eq('Widgrid - Simmons - dreamcomfort')
      end

      it 'post to simmons dream comfort' do
        begin
          switch_source
        rescue StandardError
          nil
        end

        expect(WebMock).to have_requested(:post, call_url).with(body: lead_payload)
      end
    end

    context 'when source is from widgrid to Braz Leme' do
      let(:source_name) { 'Widgrid - Simmons' }
      let(:message) { 'Simmons - ESC - dreamconfort-casa verde' }

      let(:lead_payload) do
        {
          lead: {
            message: 'av._braz_leme,_757_-_santana',
            customer: {
              name: customer.name,
              email: customer.email,
              phone: customer.phone
            },
            product: {
              name: product.name
            },
            transferred_path: {
              from: 'simmons',
              id: lead_id
            },
            source: {
              name: 'Simmons - Widgrid'
            }
          }
        }
      end

      it 'returns source name' do
        expect(switch_source).to eq('Widgrid - Simmons - dreamconfort')
      end

      it 'post to simmons dream comfort' do
        begin
          switch_source
        rescue StandardError
          nil
        end

        expect(WebMock).to have_requested(:post, call_url).with(body: lead_payload)
      end
    end
  end

  context 'when is to confortalecolchoes' do
    let(:source) do
      source = OpenStruct.new
      source.name = source_name
      source
    end

    let(:customer) do
      customer = OpenStruct.new
      customer.name = 'Marcio'
      customer.phone = '1198788899'
      customer.email = 'marcio@f1sales.com.br'

      customer
    end

    let(:product) do
      product = OpenStruct.new
      product.name = 'Exclusivas I Titanium/22 I 31/03/2022'

      product
    end

    let(:lead) do
      lead = OpenStruct.new
      lead.message = message
      lead.source = source
      lead.product = product
      lead.customer = customer
      lead.id = lead_id

      lead
    end

    let(:call_url) { 'https://confortalecolchoes.f1sales.org/public/api/v1/leads' }

    before do
      stub_request(:post, call_url)
        .with(body: lead_payload.to_json).to_return(status: 200, body: lead_created_payload.to_json, headers: {})
    end

    context 'when source is from facebook' do
      let(:source_name) { 'Facebook - Simmons' }
      let(:message) do
        'conditional_question_2: São Paulo; conditional_question_3: confortale-avenida cruzeiro do sul 1100; conditional_question_1: São Paulo'
      end
      let(:lead_payload) do
        {
          lead: {
            message: message,
            customer: {
              name: customer.name,
              email: customer.email,
              phone: customer.phone
            },
            product: {
              name: product.name
            },
            transferred_path: {
              from: 'simmons',
              id: lead_id
            },
            source: {
              name: 'Simmons - Facebook'
            }
          }
        }
      end

      it 'returns source name' do
        expect(switch_source).to eq('Facebook - Simmons - confortale')
      end

      it 'post to confortale colchoes' do
        begin
          switch_source
        rescue StandardError
          nil
        end

        expect(WebMock).to have_requested(:post, call_url).with(body: lead_payload)
      end
    end

    context 'when source is from widgrid' do
      let(:source_name) { 'WIDGRID - SIMMONS - ENCONTRE SEU COLCHÃO' }
      let(:message) { 'Simmons - ESC - confortale-avenida cruzeiro do sul 1100' }
      let(:lead_payload) do
        {
          lead: {
            message: message,
            customer: {
              name: customer.name,
              email: customer.email,
              phone: customer.phone
            },
            product: {
              name: product.name
            },
            transferred_path: {
              from: 'simmons',
              id: lead_id
            },
            source: {
              name: 'Simmons - Widgrid'
            }
          }
        }
      end

      it 'returns source name' do
        expect(switch_source).to eq('Widgrid - Simmons - confortale')
      end

      it 'post to confortale colchoes' do
        begin
          switch_source
        rescue StandardError
          nil
        end

        expect(WebMock).to have_requested(:post, call_url).with(body: lead_payload)
      end
    end
  end

  context 'when Moema was unified' do
    let(:lead) do
      lead = OpenStruct.new
      lead.source = source
      lead.message = 'conditional_question_2: São Paulo; conditional_question_3: dreamcomfort-avenida ibirapuera 2453; conditional_question_1: São Paulo'
      lead.id = lead_id

      lead
    end

    let(:source) do
      source = OpenStruct.new
      source.name = 'Facebook - Simmons'
      source
    end

    context 'when the address is Av. Ibirapuera, 2453' do
      it 'returns salesman email' do
        expect(switch_salesman).to eq({ email: 'avenidaibirapuera2453@simmons.com.br' })
      end
    end

    context 'when the address is Av. Ibirapuera, 3000' do
      before { lead.message = 'conditional_question_1: São Paulo; conditional_question_2: São Paulo; conditional_question_3: dreamcomfort-avenida ibirapuera 3000' }
      it 'returns salesman email' do
        expect(switch_salesman).to eq({ email: 'avenidaibirapuera2453@simmons.com.br' })
      end
    end
  end
end
