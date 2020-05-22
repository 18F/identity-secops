CREATE DATABASE `clouddriver` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

GRANT ALL PRIVILEGES
ON `clouddriver`.*
TO 'clouddriver'@'%' IDENTIFIED by 'clouddriver123';

CREATE DATABASE `orca` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

GRANT ALL PRIVILEGES 
ON `orca`.* 
TO 'orca'@'%' IDENTIFIED BY 'orca123';

CREATE DATABASE `front50` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

GRANT ALL PRIVILEGES
ON `front50`.*
TO 'front50'@'%' IDENTIFIED BY 'front50123';
