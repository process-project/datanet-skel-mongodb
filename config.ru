require File.expand_path('../config/environment', __FILE__)

MODEL_LOCATION = 'model'

def mapper
	@mapper ||= create_mongo_db_mapper
end

def create_mongo_db_mapper
	services = JSON.parse(ENV['VCAP_SERVICES']) if ENV['VCAP_SERVICES']

	host 			= services['mongodb-2.0'].first['credentials']['hostname'] rescue 'localhost' 
	port 			= services['mongodb-2.0'].first['credentials']['port'] rescue 27017
	database 	= services['mongodb-2.0'].first['credentials']['db'] rescue 'db'
	username 	= services['mongodb-2.0'].first['credentials']['username'] rescue nil
	password 	= services['mongodb-2.0'].first['credentials']['password'] rescue nil

	db = Mongo::Connection.new(host, port).db(database, :pool_size => 5,  :timeout => 5) 

	if username and password
		db.authenticate(username, password)
	end

	mapper = Datanet::Skel::Mongodb::Mapper.new(db)
	mapper_decorator = Datanet::Skel::MapperDecorator.new(mapper)
	mapper_decorator.model_location = File.expand_path(MODEL_LOCATION)

	mapper_decorator
end

Datanet::Skel::API.mapper = mapper
Datanet::Skel::API.storage_host = "zeus.cyfronet.pl"
run Datanet::Skel::API
