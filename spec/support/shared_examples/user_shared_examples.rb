shared_examples_for 'User' do
  describe 'validations' do
    it 'should have a valid factory' do
      expect(user).to be_valid
    end

    it 'should require a first_name' do
      user.first_name = ''
      expect(user).not_to be_valid
    end

    it 'should require a last_name' do
      user.last_name = ''
      expect(user).not_to be_valid
    end

    it 'should not require a password when a new record' do
      user.password = nil
      user.password_confirmation = nil
      user.encrypted_password = nil

      expect(user).to be_valid
    end

    it 'should require a password when being set on an existing user' do
      user.save!
      user.password = 'newpassword'
      user.password_confirmation = ''

      expect(user).not_to be_valid
    end

    it 'should not require a unique email address' do
      user.save!
      another_user = FactoryGirl.build(user.class.to_s.underscore, email: user.email)

      expect(another_user).to be_valid
    end

    it 'should not allow whitespace in email address' do
      user.email = "my email@example.com"
      expect(user).not_to be_valid

      user.email = "myemail@exam ple.com"
      expect(user).not_to be_valid

      user.email = "myemail@example.c om"
      expect(user).not_to be_valid

      user.email = "myemail@example.com"
      expect(user).to be_valid
    end
  end

  describe "#has_password?" do
    it 'should return false when encrypted_password is blank' do
      user.encrypted_password = nil
      expect(user).not_to have_password
    end

    it 'should return true when encrypted_password is present' do
      user.encrypted_password = 'abc123'
      expect(user).to have_password
    end
  end

  describe "#password_reset_pending?" do
    it "should return false when user has no password reset token" do
      user.reset_password_token = nil
      expect(user.password_reset_pending?).to eq(false)
    end

    it "should return false when user has expired password reset token" do
      user.reset_password_token = 'abc123'
      user.reset_password_sent_at = 1.month.ago
      expect(user.password_reset_pending?).to eq(false)
    end

    it "should return true when user has password reset token that has not expired" do
      user.reset_password_token = 'abc123'
      user.reset_password_sent_at = 1.minute.ago
      expect(user.password_reset_pending?).to eq(true)
    end
  end

  describe '#send_new_account_notification' do
    before(:each) do
      user.save!
      ActionMailer::Base.deliveries.clear
    end

    it "should set reset_password_token" do
      expect(user.reset_password_token).to be_nil
      user.send_new_account_notification
      expect(user.reset_password_token).not_to be_nil
    end

    it "should set reset_password_sent_at" do
      expect(user.reset_password_sent_at).to be_nil
      user.send_new_account_notification
      expect(user.reset_password_sent_at).not_to be_nil
    end

    it "should send email to user" do
      user.send_new_account_notification

      emails = ActionMailer::Base.deliveries
      expect(emails.size).to eq(1)
      expect(emails.first.to).to eq([ user.email ])
    end
  end

  describe "#username" do
    it "should be set when user is created" do
      expect(user.username).to be_blank
      user.save!
      expect(user.username).not_to be_blank
    end

    it "should be lowercase" do
      user.save!
      expect(user.username).not_to match(/[A-Z]/)
    end

    it "should only include alphabetical characters" do
      user.last_name = "O'Brien"
      user.save!
      expect(user.username[0,4]).to eq('obri')
    end
  end

  describe "#unlock!" do
    before(:each) do
      user.locked = true
      user.failed_attempts = 3
      user.save
    end

    it 'should unlock user' do
      user.unlock!
      expect(user).not_to be_locked
    end

    it 'should set failed_attempts to 0' do
      user.unlock!
      expect(user.failed_attempts).to eq(0)
    end
  end
end
