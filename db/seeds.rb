# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).

Inspiration.create(category: 'Seed', body: 'Seeded into database')

paid_user = User.new(email: 'paid@dabble.ex', first_name: Faker::Name.first_name, last_name: Faker::Name.last_name, password: 'dabble', plan: 'PRO Gumroad Monthly', gumroad_id: 1, frequency: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"])
paid_user.save

(1..12).each do |i|
  paid_user.payments.create!(
    amount: 3,
    date: Date.parse("#{Time.now.year-1}-#{i}-1"),
    comments: 'Seeded'
  )
end

(1..30).each do |i|
  image_url = i % 3 == 0 ? Faker::Placeholdit.image : nil
  paid_user.entries.create!(
    date: Faker::Date.backward(1095),
    body: ActionController::Base.helpers.simple_format(Faker::Hipster.paragraphs(3).join("\n\n")),
    image_url: image_url,
    inspiration_id: 1
  )
end

puts "Created paid user: paid@dabble.ex (with a password of 'dabble')"

free_user = User.create(email: 'free@dabble.ex', first_name: Faker::Name.first_name, last_name: Faker::Name.last_name, password: 'dabble')
free_user.save

(1..30).each do |i|
  free_user.entries.create!(
    date: Faker::Date.backward(1095),
    body: ActionController::Base.helpers.simple_format(Faker::Hipster.paragraphs(3).join("\n\n")),
    image_url: nil,
    inspiration_id: 1
  )
end

puts "Created free user: free@dabble.ex (with a password of 'dabble')"

admin_user = User.new(email: 'admin@dabble.ex', first_name: Faker::Name.first_name, last_name: Faker::Name.last_name, password: 'dabble', plan: 'PRO Forever', gumroad_id: 1, frequency: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"])
admin_user.save

(1..100).each do |i|
  image_url = i % 3 == 0 ? Faker::Placeholdit.image : nil
  admin_user.entries.create!(
    date: Faker::Date.backward(1095),
    body: ActionController::Base.helpers.simple_format(Faker::Hipster.paragraphs(3).join("\n\n")),
    image_url: image_url,
    inspiration_id: 1
  )
end

puts "Created admin user: admin@dabble.ex (with a password of 'dabble')"
