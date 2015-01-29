require 'spec_helper'

describe SerializedDateFormatter do
  describe '::format' do
    subject { SerializedDateFormatter.format(input) }

    context 'with input dd/mm/yyyy' do
      let(:input) { '11/1/2011' }
      it { should eql(Date.new(2011, 1, 11)) }
    end

    context 'with input dd/mm/yy' do
      let(:input) { '11/1/11' }
      it { should eql(Date.new(2011, 1, 11)) }
    end

    context 'with a blank input' do
      let(:input) { '' }
      it { should be_nil }
    end

    context 'with a nil input' do
      let(:input) { nil }
      it { should be_nil }
    end
  end

  describe '::parse' do
    subject { SerializedDateFormatter.parse(input) }

    context 'with input dd/mm/yyyy' do
      let(:input) { '11/1/2011' }
      it { should eql('2011-01-11') }
    end

    context 'with input dd/mm/yy' do
      let(:input) { '11/1/11' }
      it { should eql('2011-01-11') }
    end

    context 'with a blank input' do
      let(:input) { '' }
      it { should eql('') }
    end

    context 'with a nil input' do
      let(:input) { nil }
      it { should eql('') }
    end
  end
end
