# create badges if none exist

if Badge.empty?
  Rails.logger.info 'No badges exist, creating badges.'
  Badge.create_badges
end
