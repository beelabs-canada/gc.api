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
    category VARCHAR(255),
    subcategory VARCHAR(255),
    make VARCHAR(255),
    model VARCHAR(255),
    year INTEGER,
    /* children_pregnant_women VARCHAR(255),*/
    date_last_updated INTEGER
);