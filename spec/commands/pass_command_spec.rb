require 'spec_helper'

describe PassCommand do

  describe "invalid argument"
    it "should not be valid when already registered tries PASS" do
      invalid_connection = mock(:irc_connection, :registered? => true)
      cmd = PassCommand.new(invalid_connection)
      cmd.set_data(["otto.hilska@nodeta.fi","omasalasana"])
      cmd.should_not be_valid
    end

    it "should not be valid when args is nil" do
      invalid_connection = mock(:irc_connection, :registered? => true)
      cmd = PassCommand.new(invalid_connection)
      cmd.set_data([])
      cmd.should_not be_valid
    end
  end
  describe "valid argument" do
   it "should not be valid when args is nil" do
      valid_connection = mock(:irc_connection, :registered? => false)
      cmd = PassCommand.new(valid_connection)
      cmd.set_data(["example@example.com","password"])
      cmd.should be_valid
  end

  describe "irc_connection set_password" do
    it "valid input, set password" do
      valid_connection = mock(:irc_connection, :registered? => false, :email= => "something" )


      valid_connection.should_receive( :password=).with("password")
      cmd = PassCommand.new(valid_connection)
      cmd.set_data(["example@example.com","password"])
      cmd.execute!

    end
    it "setting email when execute!" do
      valid_connection = mock(:irc_connection, :registered? => false, :password= => "something")

      valid_connection.should_receive(:email=).with("example@example.com")
      cmd = PassCommand.new(valid_connection)
      cmd.set_data(["example@example.com","password"])
      cmd.execute!
    end
  end
end