require 'spec_helper'

describe EventTracer::BasicDecorator do

  class DummyUnderlyingDecoratee < Struct.new(:decoratee)

    def shout(content); content; end
    def multiply(a, b); a * b; end

  end

  subject { EventTracer::BasicDecorator.new(DummyUnderlyingDecoratee.new) }

  describe "transparent decorator" do
    it "delegates all methods to the decoratee" do
      expect(subject.shout("woah")).to eq "woah"
      expect(subject.multiply(2,3)).to eq 6
    end
  end

end
