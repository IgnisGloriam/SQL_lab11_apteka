USE master

CREATE DATABASE AptekaGraphDB

USE AptekaGraphDB



CREATE TABLE section_node (
    id INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL
) AS NODE


CREATE TABLE disease_node (
    id INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL
) AS NODE


CREATE TABLE active_substance_node (
    id INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL
) AS NODE


CREATE TABLE manufacturer_node (
    id INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    address VARCHAR(100) NOT NULL
) AS NODE

CREATE TABLE medication_node (
    id INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    annotation VARCHAR(1000) NOT NULL
) AS NODE


CREATE TABLE drug_node (
    id INT PRIMARY KEY,
    quantity INT NOT NULL CHECK (quantity >= 0),
    price DECIMAL(10,2) NOT NULL CHECK (price >= 0),
    expiration_date DATE NOT NULL
) AS NODE


CREATE TABLE employee_node (
    id INT PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    [address] VARCHAR(100) NOT NULL,
    passport VARCHAR(10) NOT NULL UNIQUE,
    profession VARCHAR(10) NOT NULL
) AS NODE


CREATE TABLE client_node (
    id INT PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    address VARCHAR(100) NOT NULL
) AS NODE


CREATE TABLE sale_node (
    id INT PRIMARY KEY,
    sale_date DATE NOT NULL,
    total_amount DECIMAL(10,2) NOT NULL CHECK (total_amount >= 0)
) AS NODE


CREATE TABLE order_node (
    id INT PRIMARY KEY,
    order_date DATE NOT NULL,
    total_amount DECIMAL(10,2) NOT NULL CHECK (total_amount >= 0)
) AS NODE

-------------------------------------------------------------------------

CREATE TABLE belongs_to_edge AS EDGE

CREATE TABLE manufactured_by_edge AS EDGE

CREATE TABLE has_indication_edge AS EDGE

CREATE TABLE contains_substance_edge AS EDGE

CREATE TABLE in_section_edge AS EDGE

CREATE TABLE sold_by_edge AS EDGE

CREATE TABLE ordered_by_edge AS EDGE

CREATE TABLE includes_drug_edge (
    quantity INT NOT NULL CHECK (quantity > 0)
) AS EDGE

CREATE TABLE includes_drug_order_edge (
    quantity INT NOT NULL CHECK (quantity > 0)
) AS EDGE


--------------------------------------------------------------------


INSERT INTO section_node (id, name)
SELECT id, name FROM apteka.dbo.section

INSERT INTO disease_node (id, name)
SELECT id, name FROM apteka.dbo.disease

INSERT INTO active_substance_node (id, name)
SELECT id, name FROM apteka.dbo.active_substance

INSERT INTO manufacturer_node (id, name, address)
SELECT id, name, address FROM apteka.dbo.manufacturer

INSERT INTO medication_node (id, name, annotation)
SELECT id, name, annotation FROM apteka.dbo.medication

INSERT INTO drug_node (id, quantity, price, expiration_date)
SELECT id, quantity, price, expiration_date FROM apteka.dbo.drug

INSERT INTO employee_node (id, full_name, address, passport, profession)
SELECT id, full_name, address, passport, profession FROM apteka.dbo.employee

INSERT INTO client_node (id, full_name, address)
SELECT id, full_name, address FROM apteka.dbo.client

INSERT INTO sale_node (id, sale_date, total_amount)
SELECT id, sale_date, total_amount FROM apteka.dbo.sale

INSERT INTO order_node (id, order_date, total_amount)
SELECT id, order_date, total_amount FROM apteka.dbo.[order]



---------------------------------------------------------------------

-- drug -> medication (принадлежит)
-- DROP TABLE IF EXISTS belongs_to_edge
INSERT INTO belongs_to_edge ($from_id, $to_id)
SELECT 
    dn.$node_id,
    mn.$node_id
FROM apteka.dbo.drug d
JOIN drug_node dn ON d.id = dn.id
JOIN medication_node mn ON d.medication_id = mn.id

-- drug -> manufacturer (произведено)
INSERT INTO manufactured_by_edge ($from_id, $to_id)
SELECT 
    dn.$node_id,
    mn.$node_id
FROM apteka.dbo.drug d
JOIN drug_node dn ON d.id = dn.id
JOIN manufacturer_node mn ON d.manufacturer_id = mn.id

-- medication -> disease (показано при)
INSERT INTO has_indication_edge ($from_id, $to_id)
SELECT 
    mn.$node_id,
    dn.$node_id
FROM apteka.dbo.medication_indication mi
JOIN medication_node mn ON mi.medication_id = mn.id
JOIN disease_node dn ON mi.disease_id = dn.id

-- medication -> active_substance (содержит)
INSERT INTO contains_substance_edge ($from_id, $to_id)
SELECT 
    mn.$node_id,
    asn.$node_id
FROM apteka.dbo.medication_substance ms
JOIN medication_node mn ON ms.medication_id = mn.id
JOIN active_substance_node asn ON ms.active_substance_id = asn.id

-- medication -> section (в разделе)
INSERT INTO in_section_edge ($from_id, $to_id)
SELECT 
    mn.$node_id,
    sn.$node_id
FROM apteka.dbo.medication m
JOIN medication_node mn ON m.id = mn.id
JOIN section_node sn ON m.section_id = sn.id

-- sale -> employee (осуществлена)
INSERT INTO sold_by_edge ($from_id, $to_id)
SELECT 
    sn.$node_id,
    en.$node_id
FROM apteka.dbo.sale s
JOIN sale_node sn ON s.id = sn.id
JOIN employee_node en ON s.employee_id = en.id

-- order -> client (сделан)
INSERT INTO ordered_by_edge ($from_id, $to_id)
SELECT 
    onn.$node_id,
    cn.$node_id
FROM apteka.dbo.[order] o
JOIN order_node onn ON o.id = onn.id
JOIN client_node cn ON o.client_id = cn.id

-- sale -> drug (включает) с количеством
INSERT INTO includes_drug_edge ($from_id, $to_id, quantity)
SELECT 
    sn.$node_id,
    dn.$node_id,
    sc.quantity
FROM apteka.dbo.sale_content sc
JOIN sale_node sn ON sc.sale_id = sn.id
JOIN drug_node dn ON sc.drug_id = dn.id

-- order -> drug (включает) с количеством
INSERT INTO includes_drug_order_edge ($from_id, $to_id, quantity)
SELECT 
    onn.$node_id,
    dn.$node_id,
    oc.quantity
FROM apteka.dbo.order_content oc
JOIN order_node onn ON oc.order_id = onn.id
JOIN drug_node dn ON oc.drug_id = dn.id


-------------------------------------------------------------

