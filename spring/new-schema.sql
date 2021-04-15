CREATE TABLE IF NOT EXISTS `users` (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `email` VARCHAR(75) NOT NULL,
    `password` VARCHAR(128) NOT NULL,
    PRIMARY KEY (`id`)
);

CREATE TABLE IF NOT EXISTS `pads` (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `name` VARCHAR(100) NOT NULL,
    `user_id` INTEGER NOT NULL,
    FOREIGN KEY (`user_id`) REFERENCES users(id),
    PRIMARY KEY (`id`)
);

CREATE TABLE notes (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `pad_id` INTEGER,
    `user_id` INTEGER NOT NULL,
    FOREIGN KEY (`pad_id`) REFERENCES pads(id),
    FOREIGN KEY (`user_id`) REFERENCES users(id),
    `name` VARCHAR(100) NOT NULL,
    `text` text NOT NULL,
    `created_at` DATETIME NOT NULL,
    `updated_at` DATETIME NOT NULL,
    PRIMARY KEY (`id`)
);
