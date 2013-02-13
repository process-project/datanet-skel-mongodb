$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'app'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'boot'
require 'json'

Bundler.require :default, ENV['RACK_ENV']

require 'datanet-skel'
require 'mongo'
require 'mapper'
require 'json'
