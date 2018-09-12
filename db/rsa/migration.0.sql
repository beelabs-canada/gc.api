-- =================
-- = RECALLS TABLE
---= @version 1.0
-- =================
CREATE TABLE recalls ( 
    id VARCHAR(64), /* SHA256 for URL */
    lang VARCHAR(3),
    data TEXT,
    title VARCHAR(255),
    abstract VARCHAR(255),
    url VARCHAR(255),
    date_issued INTEGER,
    category_id INTEGER 
);