require "spec_helper"

describe Bankin do
  before do
    subject.configure do |config|
      config.client_id = '123456789'
      config.client_secret = 'client-secret'
    end
  end

  describe "Configuration" do
    describe ".configuration" do
      it "should return Configuration class instance" do
        expect(subject.configuration).to be_a(Bankin::Configuration)
      end
    end

    describe ".configure" do
      it "should store credentials" do
        expect(subject.configuration.client_id).to eq('123456789')
        expect(subject.configuration.client_secret).to eq('client-secret')
      end
    end
  end

  describe ".api_call" do
    it "should call api with params" do
      response = double('response', headers: {}, empty?: true)

      allow(RestClient::Request).to receive(:execute) { response }
      expected_params = {
        method: :somemethod,
        url: 'https://sync.bankin.com/somepath',
        headers: {
          'Bankin-Version': '2016-01-18',
          params: {
            client_id: '123456789',
            client_secret: 'client-secret',
            some: :param
          },
          Authorization: 'Bearer some-token'
        }
      }
      expect(RestClient::Request).to receive(:execute).with(expected_params)
      subject.api_call(:somemethod, '/somepath', { some: :param }, 'some-token')
    end

    it "returns parsed object" do
      response = { key: :val }.to_json
      allow(response).to receive(:headers) { {} }
      allow(response).to receive(:empty?) { false }

      allow(RestClient::Request).to receive(:execute) { response }
      expect(subject.api_call(:whatever, 'whatever')).to eq({ 'key' => 'val' })
    end

    it "should raise Bankin::Error" do
      configure_bankin

      stub_request(:get, "https://sync.bankin.com/v2/not-found?client_id=client-id&client_secret=client-secret").
        with(headers: { 'Bankin-Version' => '2016-01-18' }).
        to_return(status: 404, body: { type: 'not-found', message: 'resource not found' }.to_json)

      expect { subject.api_call(:get, '/v2/not-found') }.to raise_error(Bankin::Error)
    end

    it 'calls .set_rate_limits method' do
      response = double('response', headers: { header: 'header' }, empty?: true)
      allow(RestClient::Request).to receive(:execute) { response }

      expect(subject).to receive(:set_rate_limits).with({ header: 'header' })

      subject.api_call :whatever, 'path'
    end
  end

  describe ".set_rate_limits" do
    before do
      rate_limits = {
        ratelimit_limit: '100',
        ratelimit_remaining: '50',
        ratelimit_reset: '2016-01-15T17:59:17.023Z'
      }

      Bankin.set_rate_limits(rate_limits)
    end

    it 'sets rate limits' do
      expect(subject.rate_limits['limit']).to eq('100')
      expect(subject.rate_limits['remaining']).to eq('50')
      expect(subject.rate_limits['reset']).to eq('2016-01-15T17:59:17.023Z')
    end
  end
end
