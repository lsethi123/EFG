shared_examples_for 'an admin viewing active and disabled users' do
  it 'displays only active users by default' do
    expect(page).to have_content(active_user.name)
    expect(page).not_to have_content(disabled_user.name)
  end

  it 'clicking on the disabled tab displays only disabled users' do
    click_link 'Disabled'

    expect(page).not_to have_content(active_user.name)
    expect(page).to have_content(disabled_user.name)
  end
end

