module Datanet
  module Skel
    module Mongodb

      class Mapper
        def initialize(mongodb)
          @db = mongodb
        end

        def collection(entity_type, username)
          Collection.new(@db[entity_type], username)
        end
      end

      class Collection
        def initialize(collection, username)
          @collection = collection
          @username = username
        end

        def ids
          @collection.find.to_a.collect do |e|
            e["_id"].to_s
          end
        end

        def add(json_doc, relations_map)
          doc = json_doc.merge('_datanet_created_by' => @username)
          added = @collection.insert(doc)
          added.to_s
        end

        def index
          entities(@collection.find)
        end

        def get id
          hash = entity(id).to_hash
          hash.delete('_id')
          hash.delete('_datanet_created_by')
          hash
        end

        def remove(id)
          @collection.remove('_id' => bson(id))
        end

        def update(id, json_doc, relations_map)
          entity = entity(id)
          json_doc.each{|k,v|
            entity[k] = v
          }
          @collection.save(entity)
        end

        def replace(id, json_doc, relations_map)
          @collection.update({"_id" => bson(id)}, json_doc)
        end

        def search(and_query)
          entities(@collection.find(query(and_query)))
        end

        private

        def entities(collection_result)
          collection_result.to_a.collect do |e|
            e['id'] = e['_id'].to_s
            e.delete '_id'
            e
          end
        end

        def json_with_relations(json_doc, relations_map)
          relations_map.each{|prop_name, related_model|
            property_value = json_doc[prop_name]
            json_doc[prop_name] = convert_into_relation(property_value, related_model) if property_value
          }
        end

        def convert_into_relation(ref_id, model_name)
          #TODO check if model and referenced object exists
          bson(ref_id)
        end

        def entity id
          result = @collection.find_one("_id" => bson(id))
          not_found!(id) unless result
          result
        end

        def bson id
          begin
            BSON::ObjectId id
          rescue BSON::InvalidObjectId
            not_found!(id)
          end
        end

        def not_found!(id)
          raise EntityNotFoundException, "Entity #{id} not found"
        end

        OPERATORS = {
          :<  => '$lt',
          :<= => '$lte',
          :>  => '$gt',
          :>=  => '$gte',
          :!= => '$ne'
        }

        def query(and_query)
          query = and_query.dup

          id = query.delete('id')
          query = query.inject({}) do |hsh, item|
            k, v = item.first, item.last
            result = {}
            if v.kind_of? Hash or v.kind_of? Array
              v_array = (v.instance_of? Array) ? v : [v]
              v_array.each do |element|
                op = element[:operator]
                if op === :contains
                  result['$in'] = element[:value]
                elsif op == :regexp
                  result = Regexp.new element[:value]
                else
                  OPERATORS.each do |operator, mongodb_operator|
                    result[mongodb_operator] = element[:value] if op === operator
                  end
                end
              end
            end
            hsh[k] = (result.instance_of? Hash and result.keys.size == 0) ? v : result
            hsh
          end

          if id and id != ''
            ids = (id.is_a? String) ? [id] : id
            query[:_id] = {
              '$in' => ids.collect { |id| BSON::ObjectId(id)  }
            }
          end
          query
        end
      end

    end
  end
end
