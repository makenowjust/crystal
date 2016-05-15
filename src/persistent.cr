require "json"

class Persistent
  FILENAME = ".crystal_persistent"

  @hash = Hash(String, JSON::Type).new

  def []=(name : String, t)
    @hash[name] = t.as(JSON::Type)
  end

  def [](name : String) : JSON::Type
    @hash[name] as JSON::Type
  end

  def save
    File.write FILENAME, @hash.to_json
  end

  def load
    if File.exists? FILENAME
      @hash = JSON.parse(File.read FILENAME).as_h
    end
  end
end

$__crystal_persistent = Persistent.new

def Persistent.save
  $__crystal_persistent.save
end

def Persistent.load
  $__crystal_persistent.load
end
