class QmfUserAndContext
  include ::SPQR::Manageable

  def QmfUserAndContext.find_by_id(oid)
    @singleton ||= QmfUserAndContext.new
    @singleton
  end
  
  def QmfUserAndContext.find_all
    @singleton ||= QmfUserAndContext.new
    [@singleton]
  end

  expose :qmf_user_id do |args|
    args.declare :uid, :sstr, :out
  end

  expose :qmf_context do |args|
    args.declare :ctx, :uint64, :out
  end
end

class QmfClicker
  include ::SPQR::Manageable
  
  def QmfClicker.find_by_id(oid)
    @singleton ||= QmfClicker.new
    @singleton
  end
  
  def QmfClicker.find_all
    @singleton ||= QmfClicker.new
    [@singleton]
  end
  
  def initialize
    @clicks = 0
  end
  
  def click
    @clicks = @clicks.succ
  end
  
  expose :click do |args| 
  end
  
  qmf_statistic :clicks, :int
  
  qmf_package_name :example
  qmf_class_name :QmfClicker
end

class QmfHello
  include ::SPQR::Manageable
  
  def QmfHello.find_by_id(oid)
    @qmf_hellos ||= [QmfHello.new]
    @qmf_hellos[0]
  end
  
  def QmfHello.find_all
    @qmf_hellos ||= [QmfHello.new]
    @qmf_hellos
  end

  def hello(name)
    "Hello, #{name}!"
  end

  expose :hello do |args|
    args.declare :name, :lstr, :in
    args.declare :result, :lstr, :out
  end
  
  qmf_package_name :example
  qmf_class_name :QmfHello
end

class QmfDummyProp
  include ::SPQR::Manageable

  def QmfDummyProp.find_by_id(oid)
    @qmf_dps ||= [QmfDummyProp.new]
    @qmf_dps[0]
  end
  
  def QmfDummyProp.find_all
    @qmf_dps ||= [QmfDummyProp.new]
    @qmf_dps
  end
  
  def service_name
    "DummyPropService"
  end
  
  qmf_property :service_name, :lstr

  qmf_class_name :QmfDummyProp
  qmf_package_name :example
end


class QmfIntegerProp
  include ::SPQR::Manageable 

  SIZE = 12
 
  def initialize(oid)
    @int_id = oid
  end

  def spqr_object_id
    @int_id
  end
  
  def QmfIntegerProp.gen_objects(ct)
    objs = []
    ct.times do |x|
      objs << (new(x))
    end
    objs
  end

  def QmfIntegerProp.find_by_id(oid)
    @qmf_ips ||= gen_objects(SIZE)
    @qmf_ips[oid]
  end
  
  def QmfIntegerProp.find_all
    @qmf_ips ||= gen_objects(SIZE)
    @qmf_ips
  end

  def next
    QmfIntegerProp.find_by_id((@int_id + 1) % QmfIntegerProp::SIZE)
  end
  
  expose :next do |args|
    args.declare :result, :objId, :out
  end

  qmf_property :int_id, :int, :index=>true

  qmf_class_name :QmfIntegerProp
  qmf_package_name :example
end

class QmfBoolProp
  include ::SPQR::Manageable 

  SIZE = 7

  def initialize(oid)
    @int_id = oid
  end

  def spqr_object_id
    @int_id
  end
 
  def QmfBoolProp.gen_objects(ct)
    objs = []
    ct.times do |x|
      objs << (new(x))
    end
    objs
  end
  
  def QmfBoolProp.find_by_id(oid)
    puts "calling QBP::find_by_id"
    @qmf_bps ||= gen_objects(SIZE)
    @qmf_bps[oid]
  end
  
  def QmfBoolProp.find_all
    puts "calling QBP::find_all"
    @qmf_bps ||= gen_objects(SIZE)
    @qmf_bps
  end
  
  def is_id_even
    @int_id % 2 == 0
  end
  
  qmf_property :int_id, :int, :index=>true
  qmf_property :is_id_even, :bool
  
  qmf_class_name :QmfBoolProp
  qmf_package_name :example
end

class Failbot
  include ::SPQR::Manageable
  
  def Failbot.find_by_id(oid)
    @failbots ||= [Failbot.new]
    @failbots[0]
  end
  
  def Failbot.find_all
    @failbots ||= [Failbot.new]
    @failbots
  end

  def fail_with_no_result
    fail 42, "This method should not succeed, with failure code 42"
  end

  expose :fail_with_no_result do |args|
  end
  
  def fail_without_expected_result
    fail 17, "This method should not succeed, with failure code 17, and should return some garbage value"
  end

  expose :fail_without_expected_result do |args|
    args.declare :result, :uint64, :out
  end  
  
  qmf_package_name :example
  qmf_class_name :Failbot
end

class QmfListArg
  include ::SPQR::Manageable 


  def qmf_oid
    1234
  end

  def spqr_object_id
    1234
  end
 
  def QmfListArg.find_by_id(oid)
    @objs ||= [QmfListArg.new]
    @objs[0]
  end
  
  def QmfListArg.find_all
    @objs ||= [QmfListArg.new]
    @objs
  end
  
  def double(ls)
    ls.map {|x| 2 * x}
  end

  expose :double do |args|
    args.declare :input, :list, :in
    args.declare :ls, :list, :out
  end
  
  qmf_class_name :QmfListArg
  qmf_package_name :example
end
