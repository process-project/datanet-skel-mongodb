module Datanet
  module Skel
    module Mongodb

      class Mapper
        def initialize(mongodb)
          @db = mongodb
        end

        def collection(entity_type)
          Collection.new @db[entity_type]
        end
      end

      class Collection
        def initialize collection
          @collection = collection
        end

        def ids
          @collection.find.to_a.collect do |e|
            e["_id"].to_s
          end
        end

        def add(json_doc, relations_map)
          added = @collection.insert(json_doc)
          added.to_s
        end

        def index
          entities(@collection.find)
        end

        def get id
          hash = entity(id).to_hash
          hash.delete '_id'
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
          puts ">>>>>>>>>>>>>>>>>> #{query(and_query)}"
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
          raise EntityNotFoundException, "Entity with #{id} not found" unless result
          result
        end

        def bson id
          BSON::ObjectId id
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

          ids = query.delete('ids')
          query = query.inject({}) do |hsh, item|
            k, v = item.first, item.last
            value = v
            if v.instance_of? Hash
              op = v[:operator]
              if op === :contains
                v = {'$in' => v[:value]}
              elsif op == :regexp
                v = Regexp.new v[:value]
              else
                OPERATORS.each do |operator, mongodb_operator|
                  v = {mongodb_operator => v[:value].to_f} if op === operator
                end
              end
            end
            hsh[k] = v
            hsh
          end

          if ids and ids != ''
            ids = ids.split(',') if ids.is_a? String
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