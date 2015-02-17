#!/usr/bin/env ruby 

require 'sqlite3'
require 'pathname'
require 'etc'
require 'yaml'

script_abs_path = File.absolute_path($0)
path = Pathname.new(script_abs_path)
script_dir = path.dirname

lib_dir = "#{script_dir}/lib/"
tpl_dir = "#{script_dir}/lib/tpl/"
conf_dir = "#{script_dir}/config/"
data_dir = "#{script_dir}/data/"

config_path = "#{conf_dir}config.yml"

config = YAML.load_file(config_path) 

arg_parser_path = "#{lib_dir}jump_arg_parser"
db_source_path = "#{lib_dir}db/" + config['datasource']['type']
opt_react_path = "#{lib_dir}option_reactor"

require arg_parser_path
require db_source_path
require opt_react_path

data_source = config['datasource']['type'].capitalize
data_class = Object.const_get("Jump").const_get("Db").const_get(data_source)

db_sqlite = data_class.getSingleton(config['datasource'], data_dir)
opt_react = Jump::OptionReactor.new(tpl_dir)

parsed_options = Jump::JumpArgParser.parse(ARGV)

data_method = parsed_options.action.to_s + 'Query'
react_method = parsed_options.action.to_s + 'Action'

host_records = db_sqlite.public_send(data_method, parsed_options)

opt_react.public_send(react_method, parsed_options, host_records)

