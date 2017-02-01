require 'fluent/plugin/filter'

class Fluent::Plugin::AmplifierFilter < Fluent::Plugin::Filter
  Fluent::Plugin.register_filter('amplifier', self)
  Fluent::Plugin.register_filter('amplifier_filter', self)

  config_param :ratio, :float

  config_param :key_names, :array, value_type: :string, default: nil
  config_param :key_pattern, :string, default: nil

  config_param :floor, :bool, default: false

  def configure(conf)
    super

    if @key_names.nil? && @key_pattern.nil?
      raise Fluent::ConfigError, "missing both of key_names and key_pattern"
    end
    if @key_names && @key_pattern
      raise Fluent::ConfigError, "cannot specify both of key_names and key_pattern"
    end
    if @key_pattern
      @key_pattern = Regexp.new(@key_pattern)
    end

    amp = @floor ? :amp_with_floor : :amp_without_floor
    self.define_singleton_method(:amp, method(amp))

    filter_method = @key_names ? :filter_with_names : :filter_with_patterns
    self.define_singleton_method(:filter, method(filter_method))
  end

  def amp_without_floor(value)
    value.to_f * @ratio
  end

  def amp_with_floor(value)
    (value.to_f * @ratio).floor
  end

  def filter(tag, time, record)
    if @key_names
      filter_with_names(tag, time, record)
    else
      filter_with_patterns(tag, time, record)
    end
  end

  def filter_with_names(tag, time, record)
    updated = {}
    @key_names.each do |key|
      val = record[key]
      next unless val
      updated[key] = amp(val)
    end
    log.trace "amplifier", tag: tag, floor: @floor, ratio: @ratio, updated: updated, original: record
    if updated.size > 0
      record.merge(updated)
    else
      record
    end
  end

  def filter_with_patterns(tag, time, record)
    updated = {}
    record.each_pair do |key, val|
      next unless val
      next unless @key_pattern.match(key)
      updated[key] = amp(val)
    end
    log.trace "amplifier", tag: tag, floor: @floor, ratio: @ratio, updated: updated, original: record
    if updated.size > 0
      record.merge(updated)
    else
      record
    end
  end
end
