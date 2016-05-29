require "spec"

File.delete Persistent::FILENAME if File.exists? Persistent::FILENAME

$$var = 0_i64

describe Persistent do
  it "can save persistent variables" do
    $$var = 1_i64
    $$var.should eq(1_i64)
    Persistent.save
    $$var = 2_i64
    Persistent.load
    $$var.should eq(1_i64)
  end
end
