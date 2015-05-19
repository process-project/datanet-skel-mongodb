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
          entities(@collection.find(query))
        end

        def get(id)
          entity(id).to_hash.tap { |e| clean_private_data(e) }
        end

        def remove(id)
          entity(id)
          @collection.remove('_id' => bson(id))
        end

        def update(id, json_doc, relations_map)
          entity = entity(id)
          json_doc.each { |k,v| entity[k] = v }
          @collection.save(entity)
        end

        def replace(id, json_doc, relations_map)
          entity(id)
          doc = json_doc.merge('_datanet_created_by' => @username)
          @collection.update({ "_id" => bson(id) }, doc)
        end

        def search(and_query)
          entities(@collection.find(query(and_query)))
        end

        private

        def json_with_relations(json_doc, relations_map)
          relations_map.each do |prop_name, related_model|
            property_value = json_doc[prop_name]
            if property_value
              json_doc[prop_name] =
                convert_into_relation(property_value, related_model)
            end
          end
        end

        def convert_into_relation(ref_id, model_name)
          #TODO check if model and referenced object exists
          bson(ref_id)
        end

        def entities(collection)
          collection.to_a.collect { |e| clean_private_data(e) }
        end

        def entity(id)
          result = @collection.find_one('_id' => bson(id))
          not_found!(id) unless result
          not_allowed! unless owned?(result)
          result
        end

        def clean_private_data(entity)
          entity.tap do |e|
            e['id'] = e['_id'].to_s
            e.delete '_id'
            e.delete('_datanet_created_by')
          end
        end

        def bson(id)
          begin
            BSON::ObjectId id
          rescue BSON::InvalidObjectId
            not_found!(id)
          end
        end

        def owned?(result)
          !private? || result['_datanet_created_by'] == @username
        end

        def private?
          Datanet::Skel::API.auth.settings.data_separation
        end

        def not_found!(id)
          raise EntityNotFoundException, "Entity #{id} not found"
        end

        def not_allowed!
          raise PermissionDenied, "Operation not allowed"
        end

        OPERATORS = {
          :<  => '$lt',
          :<= => '$lte',
          :>  => '$gt',
          :>=  => '$gte',
          :!= => '$ne'
        }

        def query(and_query = {})
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
            hsh[k] = (result.instance_of? Hash && result.keys.size == 0) ? v : result
            hsh
          end

          if id && id != ''
            ids = (id.is_a? String) ? [id] : id
            query[:_id] = { '$in' => ids.collect { |id| BSON::ObjectId(id) } }
          end
          if private?
            query[:_datanet_created_by] = { '$in' => [@username] }
          end

          query
        end
      end
    end
  end
end
