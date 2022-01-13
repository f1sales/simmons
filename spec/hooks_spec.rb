require File.expand_path '../spec_helper.rb', __FILE__
require 'ostruct'
require 'byebug'


RSpec.describe F1SalesCustom::Hooks::Lead do
  context 'when came from facebook' do
    let(:lead) do
      lead = OpenStruct.new
      lead.source = source
      lead.message = 'conditional_question_1: Belo Horizonte; conditional_question_2: Belvedere; conditional_question_3: arte do sono-avenida luiz paulo franco 981'

      lead
    end

    let(:source) do
      source = OpenStruct.new
      source.name = 'Facebook - Simmons'
      source
    end

    context 'when has store group' do
      it 'returns source name' do
        expect(described_class.switch_source(lead)).to eq('Facebook - Simmons - arte do sono')
      end

      it 'returns salesman email' do
        expect(described_class.switch_salesman(lead)).to eq({ email: 'avenidaluizpaulofranco981@simmons.com.br' })
      end
    end
  end

  context 'when came from widgrid' do
    let(:lead) do
      lead = OpenStruct.new
      lead.source = source
      lead.message = 'Simmons - ESC - grupo alfa-avenida nossa senhora de fatima 258'

      lead
    end

    let(:source) do
      source = OpenStruct.new
      source.name = 'WIDGRID - SIMMONS - ENCONTRE SEU COLCHÃO'
      source
    end

    context 'when has store group' do
      it 'returns source name' do
        expect(described_class.switch_source(lead)).to eq('Widgrid - Simmons - grupo alfa')
      end

      it 'returns salesman email' do
        expect(described_class.switch_salesman(lead)).to eq({ email: 'avenidanossasenhoradefatima258@simmons.com.br' })
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

      lead
    end

    let(:call_url) { 'https://simmonsdreamcomfort.f1sales.org/public/api/v1/leads' }

    before do
      stub_request(:post, call_url)
        .with(body: lead_payload.to_json).to_return(status: 200, body: '', headers: {})
    end

    context 'when source is from facebook' do
      let(:source_name) { 'Facebook - Simmons' }
      let(:message) { 'conditional_question_1: São Paulo; conditional_question_2: Butantã; conditional_question_3: dreamcomfort-avenida corifeu de azevedo marques 549' }
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
            source: {
              name: 'Simmons - Facebook'
            }
          }
        }
      end

      it 'returns nil' do
        expect(described_class.switch_source(lead)).to be_nil
      end

      it 'post to simmons dream comfort' do
        described_class.switch_source(lead) rescue nil

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
            source: {
              name: 'Simmons - Widgrid'
            }
          }
        }
      end

      it 'returns nil' do
        expect(described_class.switch_source(lead)).to be_nil
      end

      it 'post to simmons dream comfort' do
        described_class.switch_source(lead) rescue nil

        expect(WebMock).to have_requested(:post, call_url).with(body: lead_payload)
      end
    end
  end
end
