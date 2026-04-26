CREATE TABLE logindata (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(64) NOT NULL UNIQUE,
    pass VARCHAR(64),
    regtime DATETIME,
    logintime DATETIME,
    online VARCHAR(64),
    path VARCHAR(128)
);