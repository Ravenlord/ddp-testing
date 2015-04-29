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
 - Benchmark file for design problem "Calculated Values", trivial solution.
 -
 - @author Markus Deutschl <deutschl.markus@gmail.com>
 - @copyright 2014 Markus Deutschl
 - @license http://unlicense.org/ Unlicense
--]]


-- --------------------------------------------------------------------------------------------------------------------- Includes


pathtest = string.match(test, "(.*/)") or ""

dofile(pathtest .. "../../common.inc")


-- --------------------------------------------------------------------------------------------------------------------- Preparation functions


--- Prepare data for the calculated values row-derived benchmarks.
-- Own function for reuse.
function prepare_row_derived()
  local query
  prepare_person_names('names', 10000)
  prepare_texts('descriptions', 10000, '/tmp/description.txt')
  -- Prepare base_price and tax_rate table.
  query = [[
CREATE TABLE `prices` (
  `id` INTEGER UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `base_price` NUMERIC(7,2) NOT NULL,
  `vat_rate` NUMERIC(3,2) NOT NULL
)
]]
  db_query(query)
  -- Insert test data by joining.
  query = [[
INSERT INTO `prices` (`base_price`, `vat_rate`)
  SELECT `num1`.`value`, `num2`.`value`
    FROM (
      SELECT `value` FROM `]] .. schema_data .. [[`.`numerics` ORDER BY RAND() LIMIT 1000
    ) AS `num1`
    CROSS JOIN (
      SELECT `value` FROM `]] .. schema_data .. [[`.`numerics` WHERE `value` < 1.0 ORDER BY RAND() LIMIT 10
    ) AS `num2`
]]
  db_query(query)

  -- Create the real products table.
  query = [[
CREATE TABLE `products` (
  `id` INTEGER UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `name` VARCHAR(255) NOT NULL,
  `description` MEDIUMTEXT NOT NULL,
  `base_price` NUMERIC(7,2) NOT NULL,
  `vat_rate` NUMERIC(3,2) NOT NULL
)
]]
  db_query(query)
  -- Insert test data by joining.
  query = [[
INSERT INTO `products` (`name`, `description`, `base_price`, `vat_rate`)
  SELECT
    `names`.`name`,
    `descriptions`.`text`,
    `prices`.`base_price`,
    `prices`.`vat_rate`
  FROM `names`
    INNER JOIN `descriptions` ON `descriptions`.`id` = `names`.`id`
    INNER JOIN `prices` ON `prices`.`id` = `names`.`id`
]]
  db_query(query)

  -- Drop unnecessary tables.
  drop_table('names')
  drop_table('descriptions')
  drop_table('prices')
end

--- Prepare data for the benchmark.
-- Is called during the prepare command of sysbench in common.lua.
function prepare_data()
  prepare_row_derived()
end


-- --------------------------------------------------------------------------------------------------------------------- Benchmark functions


--- Execute the benchmark queries.
-- Is called during the run command of sysbench.
function benchmark()
  local query = [[
SELECT
  `id`,
  `name`,
  `description`,
  `base_price`,
  `vat_rate`,
  `base_price` * (1 + `vat_rate`) AS `price`
FROM `products`
WHERE `id` = ]] .. sb_rand_uniform(1, 10000)
  rs = db_query(query)
end
