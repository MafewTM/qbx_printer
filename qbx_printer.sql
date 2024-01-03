CREATE TABLE IF NOT EXISTS `printers` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `ink` int(11) DEFAULT 100,
  `coords` text DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `ink` (`ink`),
  KEY `coords` (`coords`)
) ENGINE=InnoDB AUTO_INCREMENT=7123 DEFAULT CHARSET=utf8mb4;
