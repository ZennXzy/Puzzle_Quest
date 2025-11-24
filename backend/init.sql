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

-- Example insert (use only for testing):
-- INSERT INTO users (name, email, password_hash) VALUES ('Test User', 'test@example.com', '<hash>');
