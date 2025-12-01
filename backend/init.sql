-- SQL init script for Puzzle Quest user auth
-- Run this in phpMyAdmin or mysql CLI

CREATE DATABASE IF NOT EXISTS `puzzle_quest` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `puzzle_quest`;

CREATE TABLE IF NOT EXISTS `users` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(120) DEFAULT NULL,
  `email` VARCHAR(255) NOT NULL,
  `password_hash` VARCHAR(255) NOT NULL,
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_users_email` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `user_progress` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` INT UNSIGNED NOT NULL,
  `current_level` INT NOT NULL DEFAULT 1,
  `completed_levels` JSON NOT NULL DEFAULT ('[]'),
  `saved_states` JSON NOT NULL DEFAULT ('{}'),
  `best_times` JSON NOT NULL DEFAULT ('{}'),
  `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_user_progress_user_id` (`user_id`),
  FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `sdg_trivia` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `sdg_number` TINYINT UNSIGNED NOT NULL,
  `fact` TEXT NOT NULL,
  PRIMARY KEY (`id`),
  INDEX `idx_sdg_number` (`sdg_number`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Insert SDG trivia facts (5 per SDG)
INSERT INTO `sdg_trivia` (`sdg_number`, `fact`) VALUES
-- SDG 1: No Poverty
(1, 'SDG 1 aims to eradicate extreme poverty for all people everywhere, currently measured as people living on less than $1.25 a day.'),
(1, 'By 2030, SDG 1 targets to reduce at least by half the proportion of men, women and children of all ages living in poverty.'),
(1, 'Social protection systems are crucial for SDG 1, helping to reduce poverty and inequality.'),
(1, 'In 2015, about 736 million people lived in extreme poverty, down from 1.9 billion in 1990.'),
(1, 'SDG 1 includes targets for equal rights to economic resources and access to basic services for the poor.'),

-- SDG 2: Zero Hunger
(2, 'SDG 2 aims to end hunger, achieve food security and improved nutrition, and promote sustainable agriculture.'),
(2, 'By 2030, SDG 2 targets to end all forms of malnutrition and address the nutritional needs of adolescent girls.'),
(2, 'Sustainable agriculture is key to SDG 2, doubling the productivity and incomes of small-scale food producers.'),
(2, 'About 821 million people were undernourished in 2017, representing 10.9% of the world population.'),
(2, 'SDG 2 includes maintaining genetic diversity of seeds and cultivated plants for food security.'),

-- SDG 3: Good Health and Well-being
(3, 'SDG 3 aims to ensure healthy lives and promote well-being for all at all ages.'),
(3, 'By 2030, SDG 3 targets to reduce the global maternal mortality ratio to less than 70 per 100,000 live births.'),
(3, 'Universal health coverage is a key target of SDG 3, ensuring access to quality health services.'),
(3, 'In 2016, the world lost 15 million lives due to non-communicable diseases before age 70.'),
(3, 'SDG 3 includes ending the epidemics of AIDS, tuberculosis, malaria, and neglected tropical diseases.'),

-- SDG 4: Quality Education
(4, 'SDG 4 aims to ensure inclusive and equitable quality education and promote lifelong learning opportunities.'),
(4, 'By 2030, SDG 4 targets to ensure all girls and boys complete free, equitable and quality primary and secondary education.'),
(4, 'Technical and vocational skills are emphasized in SDG 4 for employment and decent work.'),
(4, 'In 2017, 617 million children and adolescents worldwide were not achieving minimum proficiency levels in reading and mathematics.'),
(4, 'SDG 4 includes increasing the supply of qualified teachers in developing countries.'),

-- SDG 5: Gender Equality
(5, 'SDG 5 aims to achieve gender equality and empower all women and girls.'),
(5, 'By 2030, SDG 5 targets to eliminate all forms of violence against all women and girls in public and private spheres.'),
(5, 'Women\'s participation in decision-making is crucial for SDG 5, aiming for equal opportunities.'),
(5, 'Women spend about three times as many hours in unpaid domestic and care work as men.'),
(5, 'SDG 5 includes universal access to sexual and reproductive health and reproductive rights.'),

-- SDG 6: Clean Water and Sanitation
(6, 'SDG 6 aims to ensure availability and sustainable management of water and sanitation for all.'),
(6, 'By 2030, SDG 6 targets to achieve universal and equitable access to safe and affordable drinking water.'),
(6, 'Water quality is addressed in SDG 6, including reducing pollution and increasing recycling.'),
(6, 'In 2015, 2.1 billion people lacked safely managed drinking water services.'),
(6, 'SDG 6 includes protecting and restoring water-related ecosystems.'),

-- SDG 7: Affordable and Clean Energy
(7, 'SDG 7 aims to ensure access to affordable, reliable, sustainable and modern energy for all.'),
(7, 'By 2030, SDG 7 targets to increase substantially the share of renewable energy in the global energy mix.'),
(7, 'Energy efficiency is key to SDG 7, doubling the global rate of improvement in energy efficiency.'),
(7, 'In 2016, about 840 million people still lacked access to electricity.'),
(7, 'SDG 7 includes international cooperation to facilitate access to clean energy research and technology.'),

-- SDG 8: Decent Work and Economic Growth
(8, 'SDG 8 aims to promote sustained, inclusive and sustainable economic growth, full and productive employment.'),
(8, 'By 2030, SDG 8 targets to achieve full and productive employment and decent work for all women and men.'),
(8, 'Youth unemployment is addressed in SDG 8, promoting entrepreneurship and job creation.'),
(8, 'In 2017, about 172 million people worldwide were unemployed.'),
(8, 'SDG 8 includes protecting labor rights and promoting safe working environments.'),

-- SDG 9: Industry, Innovation and Infrastructure
(9, 'SDG 9 aims to build resilient infrastructure, promote inclusive and sustainable industrialization.'),
(9, 'By 2030, SDG 9 targets to develop quality, reliable, sustainable and resilient infrastructure.'),
(9, 'Innovation is central to SDG 9, increasing the number of research and development workers per million people.'),
(9, 'Infrastructure investment needs are estimated at $3.7 trillion per year globally.'),
(9, 'SDG 9 includes supporting domestic technology development and industrial diversification.'),

-- SDG 10: Reduced Inequality
(10, 'SDG 10 aims to reduce inequality within and among countries.'),
(10, 'By 2030, SDG 10 targets to progressively achieve and sustain income growth of the bottom 40% of the population.'),
(10, 'Social protection systems are emphasized in SDG 10 to reduce inequality.'),
(10, 'The richest 1% of the population owns more wealth than the bottom 50% combined.'),
(10, 'SDG 10 includes facilitating orderly, safe, regular and responsible migration.'),

-- SDG 11: Sustainable Cities and Communities
(11, 'SDG 11 aims to make cities and human settlements inclusive, safe, resilient and sustainable.'),
(11, 'By 2030, SDG 11 targets to ensure access for all to adequate, safe and affordable housing.'),
(11, 'Urban planning is key to SDG 11, reducing the adverse per capita environmental impact of cities.'),
(11, 'By 2050, 68% of the world population is projected to live in urban areas.'),
(11, 'SDG 11 includes protecting and safeguarding cultural and natural heritage.'),

-- SDG 12: Responsible Consumption and Production
(12, 'SDG 12 aims to ensure sustainable consumption and production patterns.'),
(12, 'By 2030, SDG 12 targets to achieve the sustainable management and efficient use of natural resources.'),
(12, 'Food waste reduction is addressed in SDG 12, halving per capita global food waste.'),
(12, 'Each year, an estimated one-third of all food produced for human consumption is lost or wasted.'),
(12, 'SDG 12 includes environmentally sound management of chemicals and wastes.'),

-- SDG 13: Climate Action
(13, 'SDG 13 aims to take urgent action to combat climate change and its impacts.'),
(13, 'The Paris Agreement is central to SDG 13, strengthening resilience to climate-related hazards.'),
(13, 'By 2030, SDG 13 targets to integrate climate change measures into national policies.'),
(13, 'Climate change is causing long-term shifts in weather patterns and increasing extreme weather events.'),
(13, 'SDG 13 includes improving education and awareness-raising on climate change.'),

-- SDG 14: Life Below Water
(14, 'SDG 14 aims to conserve and sustainably use the oceans, seas and marine resources.'),
(14, 'By 2030, SDG 14 targets to prevent and significantly reduce marine pollution of all kinds.'),
(14, 'Ocean acidification is addressed in SDG 14, minimizing its impacts.'),
(14, 'Over 3 billion people depend on marine and coastal biodiversity for their livelihoods.'),
(14, 'SDG 14 includes regulating harvesting and ending overfishing.'),

-- SDG 15: Life on Land
(15, 'SDG 15 aims to protect, restore and promote sustainable use of terrestrial ecosystems.'),
(15, 'By 2030, SDG 15 targets to ensure the conservation of mountain ecosystems.'),
(15, 'Biodiversity loss is tackled in SDG 15, halting deforestation and restoring degraded forests.'),
(15, 'Forests cover about 31% of the world\'s land surface and provide vital ecosystem services.'),
(15, 'SDG 15 includes combating desertification and halting land degradation.'),

-- SDG 16: Peace and Justice Strong Institutions
(16, 'SDG 16 aims to promote peaceful and inclusive societies for sustainable development.'),
(16, 'By 2030, SDG 16 targets to significantly reduce all forms of violence and related death rates.'),
(16, 'Rule of law is emphasized in SDG 16, ensuring equal access to justice for all.'),
(16, 'In 2017, about 1.1 billion people lived in countries affected by conflict or violence.'),
(16, 'SDG 16 includes reducing illicit financial flows and arms flows.'),

-- SDG 17: Partnerships for the Goal
(17, 'SDG 17 aims to strengthen the means of implementation and revitalize the global partnership for sustainable development.'),
(17, 'By 2030, SDG 17 targets to mobilize additional financial resources for developing countries.'),
(17, 'Technology transfer is key to SDG 17, promoting development and diffusion of technologies.'),
(17, 'Official development assistance reached $146.6 billion in 2017.'),
(17, 'SDG 17 includes enhancing global macroeconomic stability through policy coordination.');

-- Example insert (use only for testing):
-- INSERT INTO users (name, email, password_hash) VALUES ('Test User', 'test@example.com', '<hash>');
