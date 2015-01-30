shared_examples_for "documents controller action" do
  it 'works with a loan from the same lender' do
    dispatch

    expect(response).to be_success
  end

  it 'renders PDF document' do
    dispatch

    expect(response.content_type).to eq('application/pdf')
  end
end
