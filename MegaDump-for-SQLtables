-- Create TEMP table with columns from multiple moz_* tables
CREATE TEMP TABLE alldump (
    -- moz_places
    places_id INTEGER, url TEXT, places_title TEXT, 
    -- moz_historyvisits
    visit_id INTEGER, visit_date INTEGER, visit_place_id INTEGER,
    -- moz_bookmarks
    bookmark_id INTEGER, fk INTEGER, bm_title TEXT,
    -- moz_hosts
    host_id INTEGER, host TEXT, frecency INTEGER,
    -- moz_keywords
    keyword_id INTEGER, keyword TEXT,
    -- moz_inputhistory
    input_place_id INTEGER, input_text TEXT,
    -- moz_favicons
    favicon_id INTEGER, favicon_url TEXT,
    -- moz_items_annos
    item_anno_id INTEGER, item_id INTEGER, anno_attribute_id INTEGER,
    -- moz_annos
    anno_id INTEGER, anno_place_id INTEGER, anno_attribute_id_2 INTEGER,
    -- moz_anno_attributes
    attr_id INTEGER, attr_name TEXT,
    -- moz_bookmarks_roots
    root_id INTEGER, root_title TEXT
);

-- Insert from moz_places
INSERT INTO alldump (places_id, url, places_title)
SELECT id, url, title FROM moz_places;

-- Insert from moz_historyvisits
INSERT INTO alldump (visit_id, visit_date, visit_place_id)
SELECT id, visit_date, place_id FROM moz_historyvisits;

-- Insert from moz_bookmarks
INSERT INTO alldump (bookmark_id, fk, bm_title)
SELECT id, fk, title FROM moz_bookmarks;

-- Insert from moz_hosts
INSERT INTO alldump (host_id, host, frecency)
SELECT id, host, frecency FROM moz_hosts;

-- Insert from moz_keywords
INSERT INTO alldump (keyword_id, keyword)
SELECT id, keyword FROM moz_keywords;

-- Insert from moz_inputhistory
INSERT INTO alldump (input_place_id, input_text)
SELECT place_id, input FROM moz_inputhistory;

-- Insert from moz_favicons
INSERT INTO alldump (favicon_id, favicon_url)
SELECT id, url FROM moz_favicons;

-- Insert from moz_items_annos
INSERT INTO alldump (item_anno_id, item_id, anno_attribute_id)
SELECT id, item_id, anno_attribute_id FROM moz_items_annos;

-- Insert from moz_annos
INSERT INTO alldump (anno_id, anno_place_id, anno_attribute_id_2)
SELECT id, place_id, anno_attribute_id FROM moz_annos;

-- Insert from moz_anno_attributes
INSERT INTO alldump (attr_id, attr_name)
SELECT id, name FROM moz_anno_attributes;

-- Insert from moz_bookmarks_roots
INSERT INTO alldump (root_id, root_title)
SELECT folder_id, root_name FROM moz_bookmarks_roots;

-- View everything dumped
SELECT * FROM alldump;
