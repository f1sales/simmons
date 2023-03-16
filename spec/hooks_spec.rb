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
      lead.message = 'conditional_question_1: Belo Horizonte; conditional_question_2: Belvedere; conditional_question_3: Jardim Sao Paulo - Av Luis Dummont, 901 - Sonhos e Sonhos'
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
        expect(switch_source).to eq('Facebook - Simmons - Sonhos e Sonhos')
      end

      it 'returns salesman email' do
        expect(switch_salesman).to eq({ email: 'avluisdummont901@simmons.com.br' })
      end
    end
  end

  context 'when came from widgrid' do
    let(:lead) do
      lead = OpenStruct.new
      lead.source = source
      lead.message = 'Simmons - ESC - Mooca - Av. Paes de Barros, 155 - Grupo Yassin'

      lead
    end

    let(:source) do
      source = OpenStruct.new
      source.name = 'WIDGRID - SIMMONS - ENCONTRE SEU COLCHÃO'

      source
    end

    context 'when has store group' do
      it 'returns source name' do
        expect(switch_source).to eq('Widgrid - Simmons - Grupo Yassin')
      end

      it 'returns salesman email' do
        expect(switch_salesman).to eq({ email: 'avpaesdebarros155@simmons.com.br' })
      end
    end

    context 'when message is Sem loja' do
      before do
        lead.message = 'Sem loja'
        lead.description = 'São Paulo - SP'
      end

      it 'returns source name' do
        expect(switch_source).to eq('Widgrid - Simmons - São Paulo - SP')
      end

      it 'returns salesman email' do
        expect(switch_salesman).to be_nil
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
      let(:address) do
        [
          ['Butanta - Av Corifeu de Azevedo Marques, 547 - Dream Confort', 'av._corifeu_de_azevedo_marques,_547_-_butantã'],
          ['Moema - Av Ibirapuera, 2453 - Dream Confort', 'av._ibirapuera,_2453_-_moema'],
          ['Moema - Av Ibirapuera, 3000 - Dream Confort', 'av._ibirapuera,_3000_-_moema'],
          ['Moema - Av Ibirapuera, 3399 - Dream Confort', 'av._ibirapuera,_3399_-_moema'],
          ['Santana - Av Braz Leme, 757 - Dream Confort', 'av._braz_leme,_757_-_santana']
        ].sample
      end
      let(:message) do
        "conditional_question_1: São Paulo; conditional_question_2: São Paulo; conditional_question_3: #{address.first}"
      end

      let(:lead_payload) do
        {
          lead: {
            message: address.last,
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
        expect(switch_source).to eq('Facebook - Simmons - Dream Confort')
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
      let(:address) do
        [
          ['Butanta - Av Corifeu de Azevedo Marques, 547 - Dream Confort', 'av._corifeu_de_azevedo_marques,_547_-_butantã'],
          ['Moema - Av Ibirapuera, 2453 - Dream Confort', 'av._ibirapuera,_2453_-_moema'],
          ['Moema - Av Ibirapuera, 3000 - Dream Confort', 'av._ibirapuera,_3000_-_moema'],
          ['Moema - Av Ibirapuera, 3399 - Dream Confort', 'av._ibirapuera,_3399_-_moema']
        ].sample
      end
      let(:message) { "Simmons - ESC - #{address.first}" }
      let(:lead_payload) do
        {
          lead: {
            message: address.last,
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
        expect(switch_source).to eq('Widgrid - Simmons - Dream Confort')
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
      let(:message) { 'Simmons - ESC - Santana - Av Braz Leme, 757 - Dream Confort' }

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
        expect(switch_source).to eq('Widgrid - Simmons - Dream Confort')
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

    context 'when source is from widgrid to Av Sumare' do
      let(:source_name) { 'Widgrid - Simmons' }
      let(:message) { 'Simmons - ESC - Perdizes - Av Sumare, 1101 - Dream Comfort' }

      let(:lead_payload) do
        {
          lead: {
            message: 'perdizes_-_av_sumare,_1101_- dream_comfort',
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
        expect(switch_source).to eq('Widgrid - Simmons - Dream Comfort')
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

    context 'when source is from widgrid to Avenida Morumbi' do
      let(:source_name) { 'Widgrid - Simmons' }
      let(:message) { 'Simmons - ESC - Morumbi - Av Avenida Morumbi, 6930 - DreamComfort' }

      let(:lead_payload) do
        {
          lead: {
            message: 'morumbi_-_av_avenida_morumbi,_6930',
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
        expect(switch_source).to eq('Widgrid - Simmons - DreamComfort')
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

  context 'when Moema was unified' do
    let(:lead) do
      lead = OpenStruct.new
      lead.source = source
      lead.message = 'conditional_question_2: São Paulo; conditional_question_3: Moema - Av Ibirapuera, 2453 - Dream Confort; conditional_question_1: São Paulo'

      lead
    end

    let(:source) do
      source = OpenStruct.new
      source.name = 'Facebook - Simmons'

      source
    end

    context 'when the address is Av. Ibirapuera, 2453' do
      it 'returns salesman email' do
        expect(switch_salesman).to eq({ email: 'avibirapuera2453@simmons.com.br' })
      end
    end

    context 'when the address is Av. Ibirapuera, 3000' do
      before { lead.message = 'conditional_question_1: São Paulo; conditional_question_2: São Paulo; conditional_question_3: Moema - Av Ibirapuera, 3000 - Dream Confort' }

      it 'returns salesman email' do
        expect(switch_salesman).to eq({ email: 'avibirapuera2453@simmons.com.br' })
      end
    end
  end

  context 'when is from Widgrid' do
    let(:lead) do
      lead = OpenStruct.new
      lead.source = source
      lead.message = 'Sem loja'
      lead.description = 'Apuí - AM'

      lead
    end

    let(:source) do
      source = OpenStruct.new
      source.name = 'Widgrid - Simmons'

      source
    end

    it 'returns source name' do
      expect(switch_source).to eq('Widgrid - Simmons - Apuí - AM')
    end
  end

  context 'when is from Formulário Live' do
    let(:lead) do
      lead = OpenStruct.new
      lead.source = source
      lead.message = 'Santo André'
      lead.description = nil

      lead
    end

    let(:source) do
      source = OpenStruct.new
      source.name = 'Formulário Live'

      source
    end

    it 'returns source name' do
      expect(switch_source).to eq('Formulário Live - Santo André')
    end
  end

  context 'when is from Lead de empresas' do
    let(:lead) do
      lead = OpenStruct.new
      lead.source = source
      lead.message = 'Simmons - ESC - Botafogo - Rua General Severiano, 97 - Loja 204 - Studio do Sono'
      lead.description = 'Rio de Janeiro - RJ'

      lead
    end

    let(:source) do
      source = OpenStruct.new
      source.name = 'Lead de empresas'

      source
    end

    context 'when lead message contains salesman information' do
      it 'returns source name' do
        expect(switch_source).to eq('Lead de empresas - Studio do Sono')
      end

      it 'returns salesman email' do
        expect(switch_salesman).to eq({ email: 'ruageneralseveriano97@simmons.com.br' })
      end
    end

    context 'when lead message contains salesman information' do
      before do
        lead.message = 'Simmons - ESC - Centro - Av. Dr Getulio Vargas, 364 - Requintar Colchões'
        lead.description = 'Campo Alegre - SC'
      end

      it 'returns source name' do
        expect(switch_source).to eq('Lead de empresas - Requintar Colchões')
      end

      it 'returns salesman email' do
        expect(switch_salesman).to eq({ email: 'avdrgetuliovargas364@simmons.com.br' })
      end
    end

    context 'when message is Sem loja' do
      before do
        lead.message = 'Sem loja'
        lead.description = 'São Paulo - SP'
      end

      it 'returns source name' do
        expect(switch_source).to eq('Lead de empresas - São Paulo - SP')
      end
    end
  end

  context 'when is from Google Divre Planilhas' do
    let(:lead) do
      lead = OpenStruct.new
      lead.source = source
      lead.message = 'Message test'

      lead
    end

    let(:source) do
      source = OpenStruct.new
      source.name = 'Planilha - Decor American'

      source
    end

    it 'returns source name' do
      expect(switch_source).to eq('Planilha - Decor American')
    end
  end
end
