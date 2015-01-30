require 'spec_helper'

describe AskForHelpMailer do
  describe '#ask_an_expert' do
    let(:expert_user1) { FactoryGirl.build(:expert_lender_admin) }
    let(:expert_user2) { FactoryGirl.build(:expert_lender_user) }
    let(:user) { FactoryGirl.build(:lender_user) }
    let(:ask_an_expert) {
      AskAnExpert.new.tap { |ask_an_expert|
        ask_an_expert.expert_users = [expert_user2, expert_user1]
        ask_an_expert.message = 'Hello'
        ask_an_expert.user = user
      }
    }
    let(:email) { AskForHelpMailer.ask_an_expert_email(ask_an_expert) }

    it do
      expect(email.body).to include(user.name)
      expect(email.body).to include('Hello')
      expect(Devise.mailer_sender).to match email.from[0]
      expect(email.reply_to).to eq([user.email])
      expect(email.subject).to include('EFG')
      expect(email.to).to include(expert_user1.email)
      expect(email.to).to include(expert_user2.email)
    end
  end

  describe '#ask_cfe' do
    let(:user) { FactoryGirl.build(:lender_user) }
    let(:ask_cfe) {
      AskCfe.new.tap { |ask_an_expert|
        ask_an_expert.message = 'Excellent!'
        ask_an_expert.user = user
        ask_an_expert.user_agent = OpenStruct.new(
          browser: 'Lynx',
          os: 'ABC',
          platform: 'Foo',
          version: '1.2.3'
        )
      }
    }
    let(:email) { AskForHelpMailer.ask_cfe_email(ask_cfe) }

    it do
      expect(email.body).to include(user.name)
      expect(email.body).to include('Excellent!')
      expect(email.body).to include('Lynx, 1.2.3')
      expect(email.body).to include('Foo, ABC')
      expect(Devise.mailer_sender).to match email.from[0]
      expect(email.reply_to).to eq([user.email])
      expect(email.subject).to include('EFG')
      expect(email.to).to eq([ EFG::Application.config.cfe_support_email ])
    end
  end
end
