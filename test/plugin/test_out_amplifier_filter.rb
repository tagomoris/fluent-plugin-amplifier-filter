require 'helper'

class AmplifierFilterOutputTest < Test::Unit::TestCase
  def setup
    Fluent::Test.setup
  end

  # config_param :ratio, :float
  # config_param :key_names, :string, :default => nil
  # config_param :key_pattern, :string, :default => nil
  # config_param :floor, :bool, :default => false
  # config_param :remove_prefix, :string, :default => nil
  # config_param :add_prefix, :string, :default => nil

  CONFIG = %[
    ratio 1.5
    key_names foo,bar,baz
    remove_prefix test
    add_prefix    modified
  ]
  CONFIG2 = %[
    ratio 0.75
    floor yes
    key_pattern field.*
    remove_prefix test
  ]

  def create_driver(conf = CONFIG, tag='test')
    Fluent::Test::OutputTestDriver.new(Fluent::AmplifierFilterOutput, tag).configure(conf)
  end

  def test_configure
    assert_raise(Fluent::ConfigError) {
      d = create_driver('')
    }
    assert_raise(Fluent::ConfigError) {
      d = create_driver(%[
        ratio 1
      ])
    }
    assert_raise(Fluent::ConfigError) {
      d = create_driver(%[
        ratio 1
        key_names field1
      ])
    }
    assert_raise(Fluent::ConfigError) {
      d = create_driver(%[
        ratio 1
        add_prefix modified
      ])
    }
    assert_nothing_thrown {
      d = create_driver(%[
        ratio 1
        key_names field1
        add_prefix modified
      ])
    }
    assert_nothing_raised {
      d = create_driver(%[
        ratio 1
        key_pattern field\d+
        remove_prefix sampled
      ])
    }

    d = create_driver
    assert_equal false, d.instance.floor
    assert_equal ['foo', 'bar', 'baz'], d.instance.key_names
  end

  def test_emit
    # CONFIG = %[
    #   ratio 1.5
    #   key_names foo,bar,baz
    #   remove_prefix test
    #   add_prefix    modified
    # ]
    d1 = create_driver(CONFIG, 'test.service')
    d1.run do
      d1.emit({'name' => 'first',  'foo' => 10, 'bar' => 1, 'baz' => 20, 'zap' => 50})
      d1.emit({'name' => 'second', 'foo' => 10, 'bar' => 2, 'baz' => 40, 'zap' => 50})
    end
    emits = d1.emits
    assert_equal 2, emits.length
    assert_equal 'modified.service', emits[0][0] # tag

    first = emits[0][2]
    assert_equal 'first', first['name']
    assert_equal 15     , first['foo']
    assert_equal 1.5    , first['bar']
    assert_equal 30     , first['baz']
    assert_equal 50     , first['zap']

    second = emits[1][2]
    assert_equal 'second', second['name']
    assert_equal 15      , second['foo']
    assert_equal 3       , second['bar']
    assert_equal 60      , second['baz']
    assert_equal 50      , second['zap']

    d2 = create_driver(CONFIG, 'test')
    d2.run do
      d2.emit({'name' => 'first',  'foo' => 10, 'bar' => 1, 'baz' => 20, 'zap' => 50})
      d2.emit({'name' => 'second', 'foo' => 10, 'bar' => 2, 'baz' => 40, 'zap' => 50})
    end
    emits = d2.emits
    assert_equal 2, emits.length
    assert_equal 'modified', emits[0][0] # tag

    # CONFIG2 = %[
    #   ratio 0.75
    #   floor yes
    #   key_pattern field.*
    #   remove_prefix test
    # ]
    d3 = create_driver(CONFIG2, 'test.service')
    d3.run do
      d3.emit({'name' => 'first',  'fieldfoo' => 10, 'fieldbar' => 1, 'fieldbaz' => 20, 'zap' => 50})
      d3.emit({'name' => 'second', 'fieldfoo' => '10', 'fieldbar' => '2', 'fieldbaz' => '40', 'zap' => '50'})
    end
    emits = d3.emits
    assert_equal 2, emits.length
    assert_equal 'service', emits[0][0] # tag

    first = emits[0][2]
    assert_equal 'first', first['name']
    assert_equal 7      , first['fieldfoo']
    assert_equal 0      , first['fieldbar']
    assert_equal 15     , first['fieldbaz']
    assert_equal 50     , first['zap']

    second = emits[1][2]
    assert_equal 'second', second['name']
    assert_equal 7       , second['fieldfoo']
    assert_equal 1       , second['fieldbar']
    assert_equal 30      , second['fieldbaz']
    assert_equal '50'    , second['zap']
  end
end
