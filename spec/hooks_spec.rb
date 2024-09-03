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

  let(:customer) do
    customer = OpenStruct.new
    customer.name = 'Marcio'
    customer.phone = '1198788899'
    customer.email = 'marcio@f1sales.com.br'

    customer
  end

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

    context 'when a store no longer has an individual store' do
      before do
        lead.message = 'conditional_question_1: São Paulo; conditional_question_2: São Caetano do Sul; conditional_question_3: Mirandopolis - Av Jabaquara, 938 - Confortale'
      end

      context 'when has store group' do
        it 'returns source name' do
          expect(switch_source).to eq('Facebook - Simmons - Confortale')
        end

        it 'returns salesman email' do
          expect(switch_salesman).to eq({ email: 'avjabaquara938@simmons.com.br' })
        end
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
        expect(switch_source).to eq('Widgrid - Simmons - Concierge')
      end

      it 'returns salesman email' do
        expect(switch_salesman).to be_nil
      end
    end
  end

  context 'when is to simmons better sleep' do
    let(:source) do
      source = OpenStruct.new
      source.name = source_name

      source
    end

    let(:product) do
      product = OpenStruct.new
      product.name = 'Simmons'

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

    let(:call_url) { 'https://bettersleepcolchoes.f1sales.org/public/api/v1/leads' }

    before do
      stub_request(:post, call_url)
        .with(body: lead_payload.to_json).to_return(status: 200, body: lead_created_payload.to_json, headers: {})
    end

    context 'when is from Widgrid' do
      context 'when source is from widgrid to Better Sleep Aldeota' do
        let(:source_name) { 'Widgrid - Simmons' }
        let(:message) { 'Simmons - ESC - Aldeota - Av Padre Antonio Tomas, 749 - Better Sleep Aldeota' }

        let(:lead_payload) do
          {
            lead: {
              message: message,
              description: 'Better Sleep Aldeota',
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
          expect(switch_source).to eq('Widgrid - Simmons - Better Sleep Aldeota - Exclusivo')
        end

        it 'marks the lead as contacted' do
          begin
            switch_source
          rescue StandardError
            nil
          end

          expect(lead.interaction).to be(:contacted)
        end
      end

      context 'when source is from widgrid to Better Sleep Antonio Sales' do
        let(:source_name) { 'Widgrid - Simmons' }
        let(:message) { 'Simmons - ESC - Dionisio Torres - Av Antonio Sales, 2895 - Better Sleep Antonio Sales' }

        let(:lead_payload) do
          {
            lead: {
              message: message,
              description: 'Better Sleep Antonio Sales',
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
          expect(switch_source).to eq('Widgrid - Simmons - Better Sleep Antonio Sales - Exclusivo')
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

      context 'when source is from widgrid to Better Sleep Cambeba' do
        let(:source_name) { 'Widgrid - Simmons' }
        let(:message) { 'Simmons - ESC - Seis Bocas - Av. Washington Soares, 4527 - Better Sleep Cambeba' }

        let(:lead_payload) do
          {
            lead: {
              message: message,
              description: 'Better Sleep Cambeba',
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
          expect(switch_source).to eq('Widgrid - Simmons - Better Sleep Cambeba - Exclusivo')
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

      context 'when source is from widgrid to Better Sleep Cambeba' do
        let(:source_name) { 'Widgrid - Simmons' }
        let(:message) { 'Simmons - ESC - Seis Bocas - Av. Washington Soares, 4527 - Better Sleep Cambeba' }

        let(:lead_payload) do
          {
            lead: {
              message: message,
              description: 'Better Sleep Cambeba',
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
          expect(switch_source).to eq('Widgrid - Simmons - Better Sleep Cambeba - Exclusivo')
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

    context 'when lead is from Facebook' do
      context 'when source is from Facebook to Better Sleep Aldeota' do
        let(:source_name) { 'Facebook - Simmons' }
        let(:message) do
          'conditional_question_2: Fortaleza; conditional_question_3: Aldeota - Av Padre Antonio Tomas, 749 - Better Sleep Aldeota; conditional_question_1: Ceará'
        end

        let(:lead_payload) do
          {
            lead: {
              message: message,
              description: 'Better Sleep Aldeota',
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
          expect(switch_source).to eq('Facebook - Simmons - Better Sleep Aldeota - Exclusivo')
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

      context 'when source is from Facebook to Better Sleep Antonio Sales' do
        let(:source_name) { 'Facebook - Simmons' }
        let(:message) do
          'conditional_question_1: Ceará; conditional_question_2: Fortaleza; conditional_question_3: Dionisio Torres - Av Antonio Sales, 2895 - Better Sleep Antonio Sales'
        end

        let(:lead_payload) do
          {
            lead: {
              message: message,
              description: 'Better Sleep Antonio Sales',
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
          expect(switch_source).to eq('Facebook - Simmons - Better Sleep Antonio Sales - Exclusivo')
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

      context 'when source is from Facebook to Better Sleep Cambeba' do
        let(:source_name) { 'Facebook - Simmons' }
        let(:message) do
          'conditional_question_1: Ceará; conditional_question_2: Fortaleza; conditional_question_3: Seis Bocas - Av. Washington Soares, 4527 - Better Sleep Cambeba'
        end

        let(:lead_payload) do
          {
            lead: {
              message: message,
              description: 'Better Sleep Cambeba',
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
          expect(switch_source).to eq('Facebook - Simmons - Better Sleep Cambeba - Exclusivo')
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

    context 'when source is from Facebook to MOC Better Sleep' do
      let(:source_name) { 'Facebook - Simmons' }
      let(:message) do
        'conditional_question_1: Ceará; conditional_question_2: Fortaleza; conditional_question_3: Seis Bocas - Av. Washington Soares, 4527 - Simmons MOC Better Sleep'
      end

      let(:lead_payload) do
        {
          lead: {
            message: message,
            description: 'Simmons MOC Better Sleep',
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
        expect(switch_source).to eq('Facebook - Simmons - Simmons MOC Better Sleep')
      end

      before do
        switch_source
      rescue StandardError
        nil
      end

      it 'post to simmons dream comfort' do
        expect(WebMock).not_to have_requested(:post, call_url)
      end

      it 'marks the lead as contacted' do
        expect(lead.interaction).to be_nil
      end
    end
  end

  context 'when is to ortoluxo' do
    let(:source) do
      source = OpenStruct.new
      source.name = source_name

      source
    end

    let(:product) do
      product = OpenStruct.new
      product.name = '#Abril- #SP -Titanium 50%off'

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

    let(:call_url) { 'https://ortoluxo.f1sales.org/public/api/v1/leads' }

    before do
      stub_request(:post, call_url)
        .with(body: lead_payload.to_json).to_return(status: 200, body: lead_created_payload.to_json, headers: {})
    end

    context 'when is from Widgrid' do
      context 'when source is from widgrid to Ortoluxo Aricanduva' do
        let(:source_name) { 'Widgrid - Simmons' }
        let(:message) { 'Simmons - ESC - Aricanduva - Shopping Aricanduva - Mattress One' }

        let(:lead_payload) do
          {
            lead: {
              message: message,
              description: 'Mattress One',
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
          expect(switch_source).to eq('Widgrid - Simmons - Mattress One')
        end

        before do
          switch_source
        rescue StandardError
          nil
        end

        it 'post to simmons dream comfort' do
          expect(WebMock).to have_requested(:post, call_url).with(body: lead_payload)
        end

        it 'marks the lead as contacted' do
          expect(lead.interaction).to be(:contacted)
        end
      end
    end

    context 'when lead is from Facebook' do
      context 'when source is from Facebook to Mattress One Shopping Lar Center' do
        let(:source_name) { 'Facebook - Simmons' }
        let(:message) do
          'conditional_question_1: São Paulo; conditional_question_2: São Paulo; conditional_question_3: Vila Guilherme - Shopping Lar Center - Mattress One'
        end

        let(:lead_payload) do
          {
            lead: {
              message: message,
              description: 'Mattress One',
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
          expect(switch_source).to eq('Facebook - Simmons - Mattress One')
        end

        before do
          switch_source
        rescue StandardError
          nil
        end

        it 'post to simmons dream comfort' do
          expect(WebMock).to have_requested(:post, call_url).with(body: lead_payload)
        end

        it 'marks the lead as contacted' do
          expect(lead.interaction).to be(:contacted)
        end
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
      before do
        lead.message = 'conditional_question_1: São Paulo; conditional_question_2: São Paulo; conditional_question_3: Moema - Av Ibirapuera, 3000 - Dream Confort'
      end

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
      expect(switch_source).to eq('Widgrid - Simmons - Concierge')
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
        expect(switch_source).to eq('Lead de empresas - Concierge')
      end
    end
  end

  context 'when lead is Simmons Concierge' do
    let(:lead) do
      lead = OpenStruct.new
      lead.source = source
      lead.message = 'Simmons Concierge'

      lead
    end

    let(:source) do
      source = OpenStruct.new
      source.name = 'Lead de empresas'

      source
    end

    let(:salesman_anwser) { { email: 'simmonsconcierge@simmons.com.br' } }

    it 'returns source Lead de empresas' do
      expect(switch_source).to eq('Lead de empresas - Simmons Concierge')
    end

    it 'returns salesman' do
      expect(switch_salesman).to eq(salesman_anwser)
    end

    context 'when source is Facebook' do
      before { source.name = 'Facebook - Simmons' }

      it 'returns source name' do
        expect(switch_source).to eq('Facebook - Simmons - Simmons Concierge')
      end

      it 'returns salesman' do
        expect(switch_salesman).to eq(salesman_anwser)
      end
    end

    context 'when source is Widgrid' do
      before { source.name = 'Widgrid - Simmons' }

      it 'returns source name' do
        expect(switch_source).to eq('Widgrid - Simmons - Simmons Concierge')
      end

      it 'returns salesman' do
        expect(switch_salesman).to eq(salesman_anwser)
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

    it 'marks the lead as contacted' do
      begin
        switch_source
      rescue StandardError
        nil
      end

      expect(lead.interaction).to be_nil
    end
  end

  context 'when lead is created manually' do
    let(:lead) do
      lead = OpenStruct.new
      lead.source = source
      lead.message = ''

      lead
    end

    let(:source) do
      source = OpenStruct.new
      source.name = 'Facebook - Simmons - '

      source
    end

    it 'returns source Lead de empresas' do
      expect(switch_source).to eq('Facebook - Simmons - ')
    end

    it 'returns salesman' do
      expect(switch_salesman).to be_nil
    end

    context 'when source is Widgrid' do
      before { source.name = 'Widgrid - Simmons' }

      it 'returns source Lead de empresas' do
        expect(switch_source).to eq('Widgrid - Simmons')
      end

      it 'returns salesman' do
        expect(switch_salesman).to be_nil
      end
    end

    context 'when source is Lead de empresas' do
      before { source.name = 'Lead de empresas' }

      it 'returns source Lead de empresas' do
        expect(switch_source).to eq('Lead de empresas')
      end

      it 'returns salesman' do
        expect(switch_salesman).to be_nil
      end
    end

    context 'when source is Another source' do
      before { source.name = 'Another source' }

      it 'returns source Lead de empresas' do
        expect(switch_source).to eq('Another source')
      end

      it 'returns salesman' do
        expect(switch_salesman).to be_nil
      end
    end
  end
end
