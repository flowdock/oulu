require 'spec_helper'

describe User do
  before(:each) do
    hash = Yajl::Parser.parse('{"id":249,"nick":"Mynick","name":"Test User","email":"test@example.com","avatar":"https://example.com/avatars/123","status":null,"disabled":false,"last_activity":1330438860345,"last_ping":1330438860329}')
    @user = User.new(hash)
  end

  it "should parse its data from a JSON hash" do
    @user.id.should == 249
    @user.nick.should == 'Mynick'
    @user.name.should == 'Test User'
    @user.email.should == 'test@example.com'
    @user.status.should be_nil
  end

  it "should know its IRC host" do
    @user.irc_host.should == "Mynick!test@example.com"
  end
end
