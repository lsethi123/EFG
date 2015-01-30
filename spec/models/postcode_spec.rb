require 'spec_helper'

describe Postcode do
  describe '#==' do
    let(:postcode) { Postcode.new('EC1R 4RP') }
    subject { postcode == other }

    context 'a Postcode with the same value' do
      let(:other) { Postcode.new('EC1R 4RP') }
      it { should eql(true) }
    end

    context 'a Postcode with the same but differently formatted value' do
      let(:other) { Postcode.new('ec1r4rp') }
      it { should eql(true) }
    end

    context 'a String with the same value' do
      let(:other) { 'EC1R 4RP' }
      it { should eql(true) }
    end

    context 'a Postcode with a different value' do
      let(:other) { Postcode.new('SW1A 1AA') }
      it { should eql(false) }
    end

    context 'a String with a different value' do
      let(:other) { 'SW1A 1AA' }
      it { should eql(false) }
    end
  end

  describe '#to_s' do
    let(:postcode) { Postcode.new(value) }
    subject { postcode.to_s }

    context 'correctly formatted' do
      let(:value) { 'EC1R 4RP' }
      it { should eq('EC1R 4RP') }
    end

    context 'lower case' do
      let(:value) { 'ec1r 4rp' }
      it { should eq('EC1R 4RP') }
    end

    context 'no space' do
      let(:value) { 'EC1R4RP' }
      it { should eq('EC1R 4RP') }
    end

    context 'transposed' do
      let(:value) { 'ECIR 4RP' }
      it { should eq('EC1R 4RP') }
    end

    context 'invalid' do
      let(:value) { 'invalid' }
      it { should eq('invalid') }
    end

    context 'nil' do
      let(:value) { nil }
      it { should eq('') }
    end
  end
end
