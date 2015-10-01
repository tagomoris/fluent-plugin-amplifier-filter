class Fluent::AmplifierFilter < Fluent::Filter
  Fluent::Plugin.register_filter('amplifier_filter', self)

  config_param :ratio, :float

  config_param :key_names, :string, default: nil
  config_param :key_pattern, :string, default: nil

  config_param :floor, :bool, default: false

  # Define `log` method for v0.10.42 or earlier
  unless method_defined?(:log)
    define_method("log") { $log }
  end

  def configure(conf)
    super

    if @key_names.nil? and @key_pattern.nil?
      raise Fluent::ConfigError, "missing both of key_names and key_pattern"
    end
    if not @key_names.nil? and not @key_pattern.nil?
      raise Fluent::ConfigError, "cannot specify both of key_names and key_pattern"
    end
    if @key_names
      @key_names = @key_names.split(',')
    end
    if @key_pattern
      @key_pattern = Regexp.new(@key_pattern)
    end

    amp = if @floor
            method(:amp_with_floor)
          else
            method(:amp_without_floor)
          end
    (class << self; self; end).module_eval do
      define_method(:amp, amp)
    end
  end

  def amp_without_floor(value)
    value.to_f * @ratio
  end

  def amp_with_floor(value)
    (value.to_f * @ratio).floor
  end

  def filter_stream(tag, es)
    new_es = Fluent::MultiEventStream.new
    if @key_names
      es.each {|time,record|
        updated = {}
        @key_names.each {|key|
          val = record[key]
          next unless val
          updated[key] = amp(val)
        }
        log.debug "amplifier tag:#{tag} floor:#{@floor} ratio:#{@ratio} updated:#{updated.to_json} record:#{record.to_json}"
        if updated.size > 0
          new_es.add(time, record.merge(updated))
        else
          new_es.add(time, record.dup)
        end
      }
    else @key_pattern
      es.each {|time,record|
        updated = {}
        record.keys.each {|key|
          val = record[key]
          next unless val
          next unless @key_pattern.match(key)
          updated[key] = amp(val)
        }
        log.debug "amplifier tag:#{tag} floor:#{@floor} ratio:#{@ratio} updated:#{updated.to_json} record:#{record.to_json}"
        if updated.size > 0
          new_es.add(time, record.merge(updated))
        else
          new_es.add(time, record.dup)
        end
      }
    end
    new_es
  end
end if defined?(Fluent::Filter)
