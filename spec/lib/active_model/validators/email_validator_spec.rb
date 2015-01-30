# Copyright (c) 2012 Evently

# MIT License

# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

require 'spec_helper'

describe ActiveModel::Validations::EmailValidator do
  class Model
    include ActiveModel::Validations

    attr_accessor :attributes

    def initialize(attributes = {})
      @attributes = attributes
    end

    def read_attribute_for_validation(key)
      @attributes[key]
    end

    def email
      @attributes[:email]
    end

    def email=(email)
      @attributes[:email] = email
    end
  end

  class Person < Model
    validates :email, email: true
  end

  let(:person) { Person.new(email: 'invalid') }

  let(:options) { {attributes: [:email]} }

  def build_validator(options = {})
    ActiveModel::Validations::EmailValidator.new(
      options.merge(attributes: [:email])
    )
  end

  subject(:validator) { build_validator }

  describe '#validate' do
    context 'with a valid email address' do
      before do
        person.email = 'james@logi.cl'
      end

      it 'does not add errors' do
        validator.validate(person)
        expect(person.errors.to_a).to eq([])
      end
    end

    context 'with nil allowed' do
      subject(:validator) do
        build_validator(allow_nil: true)
      end

      before do
        person.email = nil
      end

      it 'skips adding errors is email is nil' do
        validator.validate(person)
        expect(person.errors.to_a).to eq([])
      end
    end

    context 'with blank is allowed' do
      subject(:validator) do
        build_validator(allow_blank: true)
      end

      before do
        person.email = '  '
      end

      it 'skips adding errors is email is nil' do
        validator.validate(person)
        expect(person.errors.to_a).to eq([])
      end
    end

    context 'with no message provided' do
      it 'adds a symbol to errors for I18n lookup' do
        validator.validate(person)
        expect(person.errors.to_a).to eq(['Email is invalid'])
      end
    end

    context 'with a specific error message provided' do
      subject(:validator) do
        build_validator(message: 'is kinda odd looking')
      end

      it 'uses the message you specify' do
        validator.validate(person)
        expect(person.errors.to_a).to eq(['Email is kinda odd looking'])
      end
    end
  end
end
