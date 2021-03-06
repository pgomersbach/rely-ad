#! /usr/bin/env ruby
require 'spec_helper'
require 'puppet/type'
require 'puppet/provider/reboot/linux'

describe Puppet::Type.type(:reboot).provider(:linux) do
  let(:resource) { Puppet::Type.type(:reboot).new(:provider => :linux, :name => "linux_reboot") }
  let(:provider) { resource.provider}

  it "should be an instance of Puppet::Type::Reboot::ProviderLinux" do
    provider.must be_an_instance_of Puppet::Type::Reboot::ProviderLinux
  end

  context "self.instances" do
    it "should return an empty array" do
      provider.class.instances.should == []
    end
  end

  context "when checking if the `when` property is insync" do
    it "is absent by default" do
      expect(provider.when).to eq(:absent)
    end

    it "should not reboot when setting the `when` property to refreshed" do
      provider.expects(:reboot).never

      provider.when = :refreshed
    end
  end

  context "when a reboot is triggered", :if => Puppet::Util.which('shutdown') do
    before :each do
      provider.expects(:async_shutdown).with(includes('shutdown')).at_most_once
    end

    it "stops the application by default" do
      Puppet::Application.expects(:stop!)
      provider.reboot
    end

    it "cancels the rest of the catalog transaction if apply is set to immediately" do
      resource[:apply] = :immediately
      Puppet::Application.expects(:stop!)
      provider.reboot
    end

    it "doesn't stop the rest of the catalog transaction if apply is set to finished" do
      resource[:apply] = :finished
      Puppet::Application.expects(:stop!).never
      provider.reboot
    end

    it "includes the restart flag" do
      provider.expects(:async_shutdown).with(includes('-r'))
      provider.reboot
    end

    it "includes a timeout in the future" do
      provider.expects(:async_shutdown).with(includes("+#{resource[:timeout].to_i / 60}"))
      provider.reboot
    end

    it "includes the quoted reboot message" do
      resource[:message] = "triggering a reboot"
      provider.expects(:async_shutdown).with(includes('"triggering a reboot"'))
      provider.reboot
    end
  end
end
