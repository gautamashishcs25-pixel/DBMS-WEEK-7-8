CREATE DATABASE suppliers;
CREATE TABLE Supplier (
    sid INT PRIMARY KEY,
    sname VARCHAR(50) NOT NULL,
    city VARCHAR(50) NOT NULL
);

CREATE TABLE Parts (
    pid INT PRIMARY KEY,
    pname VARCHAR(50) NOT NULL,
    color VARCHAR(30) NOT NULL
);

CREATE TABLE Catalog (
    sid INT,
    pid INT,
    cost DECIMAL(10, 2) CHECK (cost >= 0),
    PRIMARY KEY (sid, pid),
    FOREIGN KEY (sid) REFERENCES Supplier(sid),
    FOREIGN KEY (pid) REFERENCES Parts(pid)
);

INSERT INTO Supplier (sid, sname, city) VALUES
(10001, 'Acme Widget', 'Bangalore'),
(10002, 'Johns', 'Kolkata'),
(10003, 'Vimal', 'Mumbai'),
(10004, 'Reliance', 'Delhi');

INSERT INTO Parts (pid, pname, color) VALUES
(20001, 'Book', 'Red'),
(20002, 'Pen', 'Red'),
(20003, 'Pencil', 'Green'),
(20004, 'Mobile', 'Green'),
(20005, 'Charger', 'Black');

INSERT INTO Catalog (sid, pid, cost) VALUES
(10001, 20001, 10),
(10001, 20002, 10),
(10001, 20003, 30),
(10001, 20004, 10),
(10001, 20005, 10),
(10002, 20001, 10),
(10002, 20002, 20),
(10003, 20003, 30),
(10004, 20003, 40);

SELECT DISTINCT P.pname
FROM Parts P
JOIN Catalog C ON P.pid = C.pid;

SELECT S.sname
FROM Supplier S
WHERE NOT EXISTS (
    SELECT P.pid
    FROM Parts P
    WHERE NOT EXISTS (
        SELECT C.sid
        FROM Catalog C
        WHERE C.sid = S.sid AND C.pid = P.pid
    )
);

SELECT S.sname
FROM Supplier S
WHERE NOT EXISTS (
    SELECT P.pid
    FROM Parts P
    WHERE P.color = 'Red'
      AND NOT EXISTS (
          SELECT C.sid
          FROM Catalog C
          WHERE C.sid = S.sid AND C.pid = P.pid
      )
);

SELECT P.pname
FROM Parts P
JOIN Catalog C ON P.pid = C.pid
JOIN Supplier S ON C.sid = S.sid
WHERE S.sname = 'Acme Widget'
  AND P.pid NOT IN (
      SELECT C2.pid
      FROM Catalog C2
      JOIN Supplier S2 ON C2.sid = S2.sid
      WHERE S2.sname <> 'Acme Widget'
  );

SELECT DISTINCT C1.sid
FROM Catalog C1
WHERE C1.cost > (
    SELECT AVG(C2.cost)
    FROM Catalog C2
    WHERE C2.pid = C1.pid
);

SELECT C1.pid, S.sname
FROM Catalog C1
JOIN Supplier S ON C1.sid = S.sid
WHERE C1.cost = (
    SELECT MAX(C2.cost)
    FROM Catalog C2
    WHERE C2.pid = C1.pid
)
ORDER BY C1.pid;


-- ============================================================================
-- WEEK 8: ADVANCED QUERIES, VIEWS & TRIGGERS
-- ============================================================================

SELECT P.pid, P.pname, S.sname, C.cost
FROM Catalog C
JOIN Parts P ON C.pid = P.pid
JOIN Supplier S ON C.sid = S.sid
WHERE C.cost = (SELECT MAX(cost) FROM Catalog);

SELECT S.sid, S.sname
FROM Supplier S
WHERE S.sid NOT IN (
    SELECT C.sid
    FROM Catalog C
    JOIN Parts P ON C.pid = P.pid
    WHERE P.color = 'Red'
);

SELECT S.sid, S.sname, COALESCE(SUM(C.cost), 0) AS total_value
FROM Supplier S
LEFT JOIN Catalog C ON S.sid = C.sid
GROUP BY S.sid, S.sname;

SELECT S.sid, S.sname
FROM Supplier S
JOIN Catalog C ON S.sid = C.sid
WHERE C.cost < 20
GROUP BY S.sid, S.sname
HAVING COUNT(C.pid) >= 2;

SELECT C1.pid, P.pname, S.sname, C1.cost
FROM Catalog C1
JOIN Parts P ON C1.pid = P.pid
JOIN Supplier S ON C1.sid = S.sid
WHERE C1.cost = (
    SELECT MIN(C2.cost)
    FROM Catalog C2
    WHERE C2.pid = C1.pid
)
ORDER BY C1.pid;

CREATE VIEW MostExpensiveSupplierPerPart AS
SELECT C1.pid, P.pname, S.sid, S.sname, C1.cost
FROM Catalog C1
JOIN Parts P ON C1.pid = P.pid
JOIN Supplier S ON C1.sid = S.sid
WHERE C1.cost = (
    SELECT MAX(C2.cost)
    FROM Catalog C2
    WHERE C2.pid = C1.pid
);

DELIMITER //

CREATE TRIGGER PreventLowCost
BEFORE INSERT ON Catalog
FOR EACH ROW
BEGIN
    IF NEW.cost < 1 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Catalog cost cannot be below 1';
    END IF;
END //

CREATE TRIGGER SetDefaultCost
BEFORE INSERT ON Catalog
FOR EACH ROW
BEGIN
    IF NEW.cost IS NULL THEN
        SET NEW.cost = 10;
    END IF;
END //

DELIMITER ;
