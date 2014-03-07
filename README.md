# fluent-plugin-amplifier-filter

## Component

### AmplifierFilterOutput

[Fluentd](http://fluentd.org) plugin to modify numeric values of specified fields, and Re-emit with modified tags. Useful for counting values of sampled data (by fluent-plugin-sampling-filter or etc).

## Configuration

### AmplifierFilterOutput

To do x10 for messages 1/10 sampled, and to do x100 for messages 1/100 sampled:

    <match sampled_10.**>
      type amplifier_filter
      ratio 10
      remove_prefix sampled_10
      key_names counts,rates
    </match>
    
    <match sampled_100.**>
      type amplifier_filter
      ratio 100
      remove_prefix sampled_100
      key_names counts,rates
    </match>
    
    <match logs.**>
      # output configurations where to send original/modified messages...
    </match>

`key_pattern`(regexp) useful insted of `key_names`, and `add_prefix` is also useful:

    <match sampled_10.**>
      type amplifier_filter
      ratio 10
      remove_prefix sampled_10
      add_prefix summary
      key_pattern .*_(count|rate)$
    </match>
    
    <match summary.**>
      # output configurations where to send original/modified messages...
    </match>

## TODO

* consider what to do next
* patches welcome!

## Copyright

Copyright:: Copyright (c) 2012- TAGOMORI Satoshi (tagomoris)
License::   Apache License, Version 2.0
