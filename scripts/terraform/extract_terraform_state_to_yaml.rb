#!/usr/bin/env ruby

require 'json'
require 'yaml'

outputs = JSON.load($stdin)

terraform_outputs = { 'terraform_outputs' => {} }
outputs['modules'][0]['outputs'].each {|k, v|
  terraform_outputs['terraform_outputs'][k.upcase.split.join('_')] = v.fetch("value")
}

puts YAML.dump(terraform_outputs)
