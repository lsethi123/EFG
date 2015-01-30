require 'spec_helper'

describe UsernamesReminderMailer do
  let(:mailer) {
    UsernamesReminderMailer.usernames_reminder('me@example.com', %w(user1 user2))
  }

  describe '#usernames_reminder' do
    it 'has the correct to email address' do
      expect(mailer.to).to eq(['me@example.com'])
    end

    it 'contains the usernames specified' do
      expect(mailer.body).to include('user1')
      expect(mailer.body).to include('user2')
    end

    it 'has the correct from email address' do
      expect(Devise.mailer_sender).to match mailer.from[0]
    end
  end
end
