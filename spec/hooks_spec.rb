require File.expand_path '../spec_helper.rb', __FILE__
require 'ostruct'
require 'f1sales_custom/hooks'

RSpec.describe F1SalesCustom::Hooks::Lead do
  let(:lead) do
    lead = OpenStruct.new
    lead.source = source
    lead.message = 'other: sofa; loja: Boutique dos Sonhos-Av Ininga 1201; another: info'

    lead
  end

  let(:source) do
    source = OpenStruct.new
    source.name = 'Facebook - Simmons'
    source
  end

  context 'when has store group' do
    it 'returns source name' do
      expect(described_class.switch_source(lead)).to eq('Facebook - Simmons - Boutique dos Sonhos')
    end

    it 'returns salesman email' do
      expect(described_class.switch_salesman(lead)).to eq({ email: 'boutiquedossonhos_avininga1201@simmons.com.br' })
    end
  end
end
