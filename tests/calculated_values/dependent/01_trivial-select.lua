--[[!
 - This is free and unencumbered software released into the public domain.
 -
 - Anyone is free to copy, modify, publish, use, compile, sell, or distribute this software, either in source code form
 - or as a compiled binary, for any purpose, commercial or non-commercial, and by any means.
 -
 - In jurisdictions that recognize copyright laws, the author or authors of this software dedicate any and all copyright
 - interest in the software to the public domain. We make this dedication for the benefit of the public at large and to
 - the detriment of our heirs and successors. We intend this dedication to be an overt act of relinquishment in
 - perpetuity of all present and future rights to this software under copyright law.
 -
 - THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
 - WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS BE
 - LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 - OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 -
 - For more information, please refer to <http://unlicense.org/>
--]]

--[[
 - Benchmark file for design problem "Calculated Values (dependent)", trivial solution.
 -
 - @author Markus Deutschl <deutschl.markus@gmail.com>
 - @copyright 2014 Markus Deutschl
 - @license http://unlicense.org/ Unlicense
--]]


-- --------------------------------------------------------------------------------------------------------------------- Includes


pathtest = string.match(test, "(.*/)") or ""

dofile(pathtest .. "../../common.inc")


-- --------------------------------------------------------------------------------------------------------------------- Preparation functions


--- Prepare data for the calculated values dependent benchmarks.
-- Own function for reuse.
function prepare_dependent()
  local query
  prepare_person_names('names', 1000)
  prepare_texts('descriptions', 100, '/tmp/description.txt')
  prepare_dates('dates', 1000)

  -- Prepare price table.
  query = [[
CREATE TABLE `prices` (
  `id` INTEGER UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `price` NUMERIC(7,2) NOT NULL
)
]]
  db_query(query)
  -- Insert test data by joining.
  query = [[
INSERT INTO `prices` (`price`)
  SELECT `value` FROM `]] .. schema_data .. [[`.`numerics` ORDER BY RAND() LIMIT 100
]]
  db_query(query)

  -- Create the real products table.
  query = [[
CREATE TABLE `products` (
  `id` INTEGER UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `name` VARCHAR(255) NOT NULL,
  `description` MEDIUMTEXT NOT NULL,
  `price` NUMERIC(7,2) NOT NULL
)
]]
  db_query(query)
  -- Insert test data by joining.
  query = [[
INSERT INTO `products` (`name`, `description`, `price`)
  SELECT
    `names`.`name`,
    `descriptions`.`text`,
    `prices`.`price`
  FROM `names`
    INNER JOIN `descriptions` ON `descriptions`.`id` = `names`.`id`
    INNER JOIN `prices` ON `prices`.`id` = `names`.`id`
]]
  db_query(query)

  -- Create order and line_items tables.
  query = [[
CREATE TABLE `orders` (
  `id` INTEGER UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `date` DATE NOT NULL,
  `customer` VARCHAR(255) NOT NULL
)]]
  db_query(query);

  query = [[
CREATE TABLE `line_items` (
  `order_id` INTEGER UNSIGNED NOT NULL REFERENCES `orders`(`id`),
  `product_id` INTEGER UNSIGNED NOT NULL REFERENCES `products`(`id`),
  `amount` INTEGER UNSIGNED NOT NULL,
  PRIMARY KEY (`order_id`, `product_id`)
)]]
  db_query(query)

  -- Insert orders.
  query = [[
  INSERT INTO `orders` (`date`, `customer`)
    SELECT `dates`.`date`, `names`.`name`
    FROM `dates` CROSS JOIN `names`
    ORDER BY RAND()
    LIMIT 1000
]]
  db_query(query)

  -- Insert line items.
  for i = 1, 1000 do
    query = [[
INSERT INTO `line_items` (`product_id`, `order_id`, `amount`)
  SELECT `id`, ]] .. i .. [[, FLOOR(RAND() * (100)) + 1
  FROM `products`
  ORDER BY RAND()
  LIMIT 10
]]
    db_query(query)
  end

  -- Drop unnecessary tables.
  drop_table('names')
  drop_table('descriptions')
  drop_table('prices')
  drop_table('dates')
end

--- Prepare data for the benchmark.
-- Is called during the prepare command of sysbench in common.lua.
function prepare_data()
  prepare_dependent()
end


-- --------------------------------------------------------------------------------------------------------------------- Benchmark functions


--- Execute the benchmark queries.
-- Is called during the run command of sysbench.
function benchmark()
  local query = [[
SELECT
  p.`id`,
  p.`name`,
  SUM(l.`amount`) AS `amount_ordered`
FROM `products` AS p
  INNER JOIN `line_items` AS `l` ON p.`id` = l.`product_id`
GROUP BY p.`id`, p.`name`
ORDER BY `amount_ordered` DESC
]]
  rs = db_query(query)
end
