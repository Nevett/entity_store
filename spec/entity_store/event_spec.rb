require 'spec_helper'

class DummyValue
  include EntityValue
  attr_accessor :town, :county

end

class DummyEvent
  include Event
  attr_accessor :name
  time_attribute :updated_at, :sent_at
  entity_value_attribute :address, DummyValue
end

describe Event do
  before(:each) do
    @id = random_integer
    @version = random_integer
    @name = random_string
    @time = random_time
    @town = random_string
    @county = random_string
  end
  describe "#initialize" do

    subject { DummyEvent.new({:entity_id => @id, :entity_version => @version, :name => @name, :updated_at => @time, :sent_at => nil, :address => {:town => @town, :county => @county}})}

    it "should set entity_id" do
      subject.entity_id.should eq(@id)
    end
    it "should set entity_version" do
      subject.entity_version.should eq(@version)
    end
    it "should set name" do
      subject.name.should eq(@name)
    end
    it "should set updated_at" do
      subject.updated_at.should eq(@time)
    end
    it "should set town" do
      subject.address.town.should eq(@town)
    end
    it "should set county" do
      subject.address.county.should eq(@county)
    end
  end

  describe "#attributes" do
    before(:each) do
      @event = DummyEvent.new(:entity_id => @id, :entity_version => @version, :name => @name, :updated_at => @time, :address => DummyValue.new(:town => @town, :county => @county))
    end

    subject { @event.attributes }

    it "returns a hash of the attributes" do
      subject.should eq({:entity_id => @id, :entity_version => @version, :name => @name, :updated_at => @time, :sent_at => nil, :address => {:town => @town, :county => @county}})
    end
  end

  describe ".time_attribute" do
    before(:each) do
      @event = DummyEvent.new
      @time = random_time
    end
    context "updated_at" do
      subject { @event.updated_at = @time.to_s }

      it "parses the time field when added as a string" do
        subject
        @event.updated_at.to_i.should eq(@time.to_i)
      end
    end
    context "sent_at" do
      subject { @event.updated_at = @time.to_s }

      it "parses the time field when added as a string" do
        subject
        @event.updated_at.to_i.should eq(@time.to_i)
      end
    end
  end

  describe ".value_attribute" do
    before(:each) do
      @event = DummyEvent.new
    end
    context "assign a value" do
      before(:each) do
        @value = DummyValue.new(:town => random_string, :county => random_string)
        @event.address = @value
      end
      it "assigns town" do
        @event.address.town.should eq(@value.town)
      end
      it "assigns county" do
        @event.address.county.should eq(@value.county)
      end
    end
    context "assign a hash" do
      before(:each) do
        @hash = { 'town' => random_string, 'county' => random_string }
        @event.address = @hash
      end
      it "assigns town" do
        @event.address.town.should eq(@hash['town'])
      end
      it "assigns county" do
        @event.address.county.should eq(@hash['county'])
      end
    end
  end
end
