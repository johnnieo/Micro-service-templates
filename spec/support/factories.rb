require 'faker' unless defined? Faker

FactoryGirl.define do
  sequence :random_id do
    Kernel.rand(4_000_000_000).to_s
  end

  sequence :object_id do
    BSON::ObjectId.new
  end
end
