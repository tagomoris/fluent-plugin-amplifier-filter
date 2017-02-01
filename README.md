# fluent-plugin-amplifier-filter

[Fluentd](http://fluentd.org) plugin to modify numeric values of specified fields. Useful for counting values of sampled data (by fluent-plugin-sampling-filter or etc).

## Configuration

### AmplifierFilter

To do 10x for count values from messages 1/10 sampled, and to do 100x for 1/100 sampled:

    <label @sampled>
      <filter big.service> # I know its logs are sampled into 1/10
        @type amplifier
        ratio 10
        key_names count, rate
      </filter>
      
      <filter huge.service> # I know its logs are sampled into 1/100
        @type amplifier
        ratio 100
        key_pattern .*_(count|rate)$
      </filter>
      
      <match **>
        # output result to visualization tools, or ....
      </match>
    </label>

There is an option to `floor`(bool) the result of amplifying numeric values into integer. Its default value is `false`.

### AmplifierFilterOutput

**NOTE: This output plugin is deprecated. Use 'amplifier' filter plugin instead.**

To do x10 for messages 1/10 sampled, and to do x100 for messages 1/100 sampled:

    <match sampled_10.**>
      @type amplifier_filter
      ratio 10
      remove_prefix sampled_10
      key_names counts,rates
    </match>
    
    <match sampled_100.**>
      @type amplifier_filter
      ratio 100
      remove_prefix sampled_100
      key_names counts,rates
    </match>
    
    <match logs.**>
      # output configurations where to send original/modified messages...
    </match>

`key_pattern`(regexp) useful insted of `key_names`, and `add_prefix` is also useful:

    <match sampled_10.**>
      @type amplifier_filter
      ratio 10
      remove_prefix sampled_10
      add_prefix summary
      key_pattern .*_(count|rate)$
    </match>

    <match summary.**>
      # output configurations where to send original/modified messages...
      </match>

## TODO

* patches welcome!

## Copyright

Copyright:: Copyright (c) 2012- TAGOMORI Satoshi (tagomoris)
License::   Apache License, Version 2.0
