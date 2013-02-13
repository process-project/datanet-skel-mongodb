module Datanet
	module Skel
		module Mongodb

			class Mapper
				def initialize mongodb
					@db = mongodb
				end

				def collection entity_type
					Collection.new @db[entity_type]
				end			
			end

			class Collection 
				def initialize collection
					@collection = collection
				end

				def ids
					ids = []
					@collection.find.to_a.each { |e|
			  			ids << e["_id"].to_s                            	      		
					}
					ids
				end

				def add json_doc
          # TODO przemysleć specyficzną obsługę dla typu plikowego - dodawane relacje moga być obustronne
          # + sprzątanie nieaktywnych plików z infrastruktury
					added = @collection.insert(json_doc)
					added.to_s
				end				

				def get id									
					hash = entity(id).to_hash
					hash.delete '_id'			
					hash						
				end
        #
				def remove id
					@collection.remove('_id' => bson(id))
				end

				def update id, json_doc
					entity = entity(id)
					json_doc.each{|k,v|
						entity[k] = v
					}
					@collection.save(entity)
				end

				def replace id, json_doc
					@collection.update({"_id" => bson(id)}, json_doc)
				end

				private

				def entity id
					result = @collection.find_one("_id" => bson(id))					
					raise EntityNotFoundException, "Entity with #{id} not found" unless result						
					result
				end

				def bson id
					BSON::ObjectId id
				end
			end					

		end  
	end
end