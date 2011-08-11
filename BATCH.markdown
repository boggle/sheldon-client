# Here's how we do batch things

SheldonClient.batch do |batch|
  batch.create :connection, { ... }
end
