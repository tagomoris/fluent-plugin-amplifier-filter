require 'helper'

class AmplifierFilterTest < Test::Unit::TestCase
  def setup
    if not defined?(Fluent::Filter)
      omit("Fluent::Filter is not defined. Use fluentd 0.12 or later.")
    end

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
  ]
  CONFIG2 = %[
    ratio 0.75
    floor yes
    key_pattern field.*
  ]

  def create_driver(conf = CONFIG, tag='test')
    Fluent::Test::FilterTestDriver.new(Fluent::AmplifierFilter, tag).configure(conf)
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
    assert_nothing_thrown {
      d = create_driver(%[
        ratio 1
        key_names field1
      ])
    }
    assert_nothing_raised {
      d = create_driver(%[
        ratio 1
        key_pattern field\d+
      ])
    }

    d = create_driver
    assert_equal false, d.instance.floor
    assert_equal ['foo', 'bar', 'baz'], d.instance.key_names
  end

  def test_filter_1
    # CONFIG = %[
    #   ratio 1.5
    #   key_names foo,bar,baz
    # ]
    d1 = create_driver(CONFIG, 'test.service')
    d1.run do
      d1.filter({'name' => 'first',  'foo' => 10, 'bar' => 1, 'baz' => 20, 'zap' => 50})
      d1.filter({'name' => 'second', 'foo' => 10, 'bar' => 2, 'baz' => 40, 'zap' => 50})
    end
    filtered = d1.filtered_as_array
    assert_equal 2, filtered.length
    assert_equal 'test.service', filtered[0][0] # tag

    first = filtered[0][2]
    assert_equal 'first', first['name']
    assert_equal 15     , first['foo']
    assert_equal 1.5    , first['bar']
    assert_equal 30     , first['baz']
    assert_equal 50     , first['zap']

    second = filtered[1][2]
    assert_equal 'second', second['name']
    assert_equal 15      , second['foo']
    assert_equal 3       , second['bar']
    assert_equal 60      , second['baz']
    assert_equal 50      , second['zap']
  end

  def test_filter_2
    # CONFIG = %[
    #   ratio 1.5
    #   key_names foo,bar,baz
    # ]
    d2 = create_driver(CONFIG, 'test')
    d2.run do
      d2.filter({'name' => 'first',  'foo' => 10, 'bar' => 1, 'baz' => 20, 'zap' => 50})
      d2.filter({'name' => 'second', 'foo' => 10, 'bar' => 2, 'baz' => 40, 'zap' => 50})
    end
    filtered = d2.filtered_as_array
    assert_equal 2, filtered.length
    assert_equal 'test', filtered[0][0] # tag
  end

  def test_filter_3
    # CONFIG2 = %[
    #   ratio 0.75
    #   floor yes
    #   key_pattern field.*
    # ]
    d3 = create_driver(CONFIG2, 'test.service')
    d3.run do
      d3.filter({'name' => 'first',  'fieldfoo' => 10, 'fieldbar' => 1, 'fieldbaz' => 20, 'zap' => 50})
      d3.filter({'name' => 'second', 'fieldfoo' => '10', 'fieldbar' => '2', 'fieldbaz' => '40', 'zap' => '50'})
    end
    filtered = d3.filtered_as_array
    assert_equal 2, filtered.length
    assert_equal 'test.service', filtered[0][0] # tag

    first = filtered[0][2]
    assert_equal 'first', first['name']
    assert_equal 7      , first['fieldfoo']
    assert_equal 0      , first['fieldbar']
    assert_equal 15     , first['fieldbaz']
    assert_equal 50     , first['zap']

    second = filtered[1][2]
    assert_equal 'second', second['name']
    assert_equal 7       , second['fieldfoo']
    assert_equal 1       , second['fieldbar']
    assert_equal 30      , second['fieldbaz']
    assert_equal '50'    , second['zap']
  end
end
