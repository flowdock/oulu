require 'spec_helper'

describe User do
  before(:each) do
    hash = Yajl::Parser.parse('{"id":249,"nick":"Mynick","name":"Test User","email":"test@example.com","avatar":"https://example.com/avatars/123","status":null,"disabled":false,"last_activity":1330438860345,"last_ping":1330438860329}')
    @user = User.new(hash)
  end

  it "should parse its data from a JSON hash" do
    expect(@user.id).to eq(249)
    expect(@user.nick).to eq('Mynick')
    expect(@user.name).to eq('Test User')
    expect(@user.email).to eq('test@example.com')
    expect(@user.status).to be_nil
  end

  it "should know its IRC host" do
    expect(@user.irc_host).to eq("Mynick!test@example.com")
  end

  describe "#build_message" do
    subject {
      @user.build_message(content: "foo")
    }
    it "sets to parameter" do
      expect(subject[:to]).to eq("249")
    end

    it "message data" do
      expect(subject[:content]).to eq("foo")
    end
  end
end
