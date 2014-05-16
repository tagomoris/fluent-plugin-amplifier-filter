class Fluent::AmplifierFilterOutput < Fluent::Output
  Fluent::Plugin.register_output('amplifier_filter', self)

  config_param :ratio, :float

  config_param :key_names, :string, :default => nil
  config_param :key_pattern, :string, :default => nil

  config_param :floor, :bool, :default => false

  config_param :remove_prefix, :string, :default => nil
  config_param :add_prefix, :string, :default => nil

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

    if not @remove_prefix and not @add_prefix
      raise Fluent::ConfigError, "missing both of remove_prefix and add_prefix"
    end
    if @remove_prefix
      @removed_prefix_string = @remove_prefix + '.'
      @removed_length = @removed_prefix_string.length
    end
    if @add_prefix
      @added_prefix_string = @add_prefix + '.'
    end
  end

  def amp_without_floor(value)
    value.to_f * @ratio
  end

  def amp_with_floor(value)
    (value.to_f * @ratio).floor
  end

  def emit(tag, es, chain)
    if @remove_prefix and
        ( (tag.start_with?(@removed_prefix_string) and tag.length > @removed_length) or tag == @remove_prefix)
      tag = tag[@removed_length..-1]
    end
    if @add_prefix
      tag = if tag and tag.length > 0
              @added_prefix_string + tag
            else
              @add_prefix
            end
    end

    pairs = []
    if @key_names
      es.each {|time,record|
        updated = {}
        @key_names.each {|key|
          val = record[key]
          next unless val
          updated[key] = amp(val)
        }
        log.debug "amplifier tag:#{tag} amp:#{self.method(:amp)}"
        log.debug "amplifier tag:#{tag} debug ratio:#{@ratio} updated:#{updated.to_json} record:#{record.to_json}"
        if updated.size > 0
          pairs.push [time, record.merge(updated)]
        else
          pairs.push [time, record.dup]
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
        log.debug "amplifier tag:#{tag} amp:#{self.method(:amp)}"
        log.debug "amplifier tag:#{tag} debug ratio:#{@ratio} updated:#{updated.to_json} record:#{record.to_json}"
        if updated.size > 0
          pairs.push [time, record.merge(updated)]
        else
          pairs.push [time, record.dup]
        end
      }
    end
    Fluent::Engine.emit_array(tag, pairs)

    chain.next
  end
end
