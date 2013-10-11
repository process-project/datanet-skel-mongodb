require 'spec_helper'

describe Datanet::Skel::Mongodb::Collection do
  let(:collection_mapper) { double }
  let(:collection) { Datanet::Skel::Mongodb::Collection.new(collection_mapper) }

  describe '#search' do
    it 'should return all record with attr value' do
      expect(collection_mapper).to receive(:find).with({'name' => 'marek'})
      collection.search({'name' => 'marek'})
    end

    it 'should return all record with ids in array' do
      expect(collection_mapper).to receive(:find).with({_id: {'$in' => [BSON::ObjectId('523af2eb866488292e0056c3'), BSON::ObjectId('523af2eb866488292e0056c4')]}})

      collection.search({'ids' => '523af2eb866488292e0056c3,523af2eb866488292e0056c4' })
    end

    it 'should support < operator' do
      expect(collection_mapper).to receive(:find).with({'age' => {'$lt' => '24'}})
      collection.search({'age' => {value: '24', operator: :<}})
    end

    it 'should support <= operator' do
      expect(collection_mapper).to receive(:find).with({'age' => {'$lte' => '24'}})
      collection.search({'age' => {value: '24', operator: :<=}})
    end

    it 'should support > operator' do
      expect(collection_mapper).to receive(:find).with({'age' => {'$gt' => '24'}})
      collection.search({'age' => {value: '24', operator: :>}})
    end

    it 'should support >= operator' do
      expect(collection_mapper).to receive(:find).with({'age' => {'$gte' => '24'}})
      collection.search({'age' => {value: '24', operator: :>=}})
    end

    it 'should support != operator' do
      expect(collection_mapper).to receive(:find).with({'age' => {'$ne' => '24'}})
      collection.search({'age' => {value: '24', operator: :!=}})
    end

    it 'support contains operator' do
      expect(collection_mapper).to receive(:find).with({'age' => {'$in' => [1, 2, 3]}})
      collection.search({'age' => {value: [1, 2, 3], operator: :contains}})
    end

    it 'support regexp operator' do
      expect(collection_mapper).to receive(:find).with({'name' => /\Aa\/.*\/\z/})
      collection.search({'name' => {value: '\Aa\/.*\/\z', operator: :regexp}})
    end

    it 'support compound queries' do
      expect(collection_mapper).to receive(:find).with({'age' => {'$gt' => 20, '$lt' => 30}})
      collection.search({'age' => [{value: 20, operator: :>}, {value: 30, operator: :<}]})
    end
  end
end