BEGIN;

INSERT INTO place_category (name) VALUES ('Shirts');
INSERT INTO place (name,place_category_id) VALUES ('TeeTurtle',1);
INSERT INTO transaction (date,amount,balance,type,place_id) VALUES (
  date(now())
, -10
, 90
, 'atm_operator_fee'
, 1
);

COMMIT;
