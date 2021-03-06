require File.expand_path('../config/environment', __FILE__)
require File.expand_path('../config/settings', __FILE__)

MODEL_LOCATION = 'model'

def mapper
  @mapper ||= create_mongo_db_mapper
end

def ca_payload
  @ca_payload ||= File.read 'config/simple_ca.crt'
end

def crl_location
  #default location of simpleca crl, exists on api.paas.datanet.plgrid.pl
  @crl_location ||= "/etc/grid-security/certificates/afed687d.r0"
end

def create_mongo_db_mapper
  services = JSON.parse(ENV['VCAP_SERVICES']) if ENV['VCAP_SERVICES']

  host      = services['mongodb-2.0'].first['credentials']['hostname'] rescue 'localhost'
  port      = services['mongodb-2.0'].first['credentials']['port'] rescue 27017
  database  = services['mongodb-2.0'].first['credentials']['db'] rescue 'db'
  username  = services['mongodb-2.0'].first['credentials']['username'] rescue nil
  password  = services['mongodb-2.0'].first['credentials']['password'] rescue nil

  db = Mongo::Connection.new(host, port).db(database, :pool_size => 10,  :timeout => 60)

  if username and password
    db.authenticate(username, password)
  end

  mapper = Datanet::Skel::Mongodb::Mapper.new(db)
  mapper_decorator = Datanet::Skel::MapperDecorator.new(mapper)
  mapper_decorator.model_location = File.expand_path(MODEL_LOCATION)

  mapper_decorator
end

grid_proxy_auth = Datanet::Skel::GridProxyAuth.new ca_payload, crl_location

auth = Datanet::Skel::RepositoryAuth.new
auth.repo_secret_path = 'config/.secret'
auth.settings = Datanet::Skel::Mongodb::Settings
auth.authenticator = grid_proxy_auth

Datanet::Skel::API.mapper = mapper
Datanet::Skel::API.auth = auth
Datanet::Skel::API.auth_storage = grid_proxy_auth

use Rack::Cors do
  allow do
    origins *(auth.cors_origins)
    resource '*', :headers => :any, :methods => [:get, :post, :put, :delete, :options]

    Datanet::Skel::API.auth.cors = self
  end
end
use CatchErrors

run Datanet::Skel::API
