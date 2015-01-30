shared_examples_for 'a CSV download' do
  describe 'headers' do
    describe 'Content-Disposition' do
      it 'has the correct filename extension' do
        dispatch

        content_disposition = response.headers['Content-Disposition']
        filename = /\bfilename="([^"]+)"/.match(content_disposition)[1]

        expect(File.extname(filename)).to eq('.csv')
      end
    end
  end
end
