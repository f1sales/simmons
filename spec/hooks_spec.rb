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
      lead.message = 'arte do sono-avenida luiz paulo franco 981'

      lead
    end

    let(:source) do
      source = OpenStruct.new
      source.name = 'Widgrid - Simmons'
      source
    end

    context 'when has store group' do
      it 'returns source name' do
        expect(described_class.switch_source(lead)).to eq('Widgrid - Simmons - arte do sono')
      end

      it 'returns salesman email' do
        expect(described_class.switch_salesman(lead)).to eq({ email: 'avenidaluizpaulofranco981@simmons.com.br' })
      end
    end
  end
end
