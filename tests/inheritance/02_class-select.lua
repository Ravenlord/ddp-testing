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
 - Benchmark file for design problem "Inheritance", solution "Class Table Inheritance".
 -
 - @author Markus Deutschl <deutschl.markus@gmail.com>
 - @copyright 2014 Markus Deutschl
 - @license http://unlicense.org/ Unlicense
--]]


-- --------------------------------------------------------------------------------------------------------------------- Includes


pathtest = string.match(test, "(.*/)") or ""

dofile(pathtest .. "../common.inc")
dofile(pathtest .. "01_single-select.lua")


-- --------------------------------------------------------------------------------------------------------------------- Preparation functions


--- Prepare data for the benchmark.
--  Is called during the prepare command of sysbench in common.lua.
function prepare_data()
  local query
  -- Reuse the data preparation.
  prepare_schema()

  -- Create the new schema and convert from Single Table Inheritance to Class Table Inheritance.
  db_query('ALTER TABLE `employees` RENAME `emp`')
  query = [[
  CREATE TABLE `employees` (
  `id` INTEGER UNSIGNED PRIMARY KEY,
  `name` VARCHAR(255) NOT NULL
)]]
  db_query(query)
  query = [[
INSERT INTO `employees` (`id`, `name`)
  SELECT `id`, `name` FROM `emp`
]]
  db_query(query)
  db_query('ALTER TABLE `employees` MODIFY `id` INTEGER UNSIGNED AUTO_INCREMENT')

  query = [[
CREATE TABLE `contractors` (
  `id` INTEGER UNSIGNED PRIMARY KEY,
  `project` VARCHAR(255) NOT NULL,
  `start_date` DATE NOT NULL,
  `end_date` DATE,
  FOREIGN KEY (`id`) REFERENCES `employees`(`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE
)]]
  db_query(query)
  query = [[
INSERT INTO `contractors` (`id`, `project`, `start_date`, `end_date`)
  SELECT `id`, `project`, `start_date`, `end_date` FROM `emp` WHERE `type` = 3;
]]
  db_query(query)


  query = [[
CREATE TABLE `regular_employees` (
  `id` INTEGER UNSIGNED PRIMARY KEY,
  `office` INTEGER(3) UNSIGNED NOT NULL,
  `phone` INTEGER(5) UNSIGNED,
  FOREIGN KEY (`id`) REFERENCES `employees`(`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE
)]]
  db_query(query)
  query = [[
INSERT INTO `regular_employees` (`id`, `office`, `phone`)
  SELECT `id`, `office`, `phone` FROM `emp` WHERE `type` = 1 OR `type` = 2;
]]
  db_query(query)

  query = [[
CREATE TABLE `managers` (
  `id` INTEGER UNSIGNED PRIMARY KEY,
  `division` VARCHAR(255) NOT NULL,
  `board` VARCHAR(255),
  FOREIGN KEY (`id`) REFERENCES `regular_employees`(`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE
)]]
  db_query(query)
  query = [[
INSERT INTO `managers` (`id`, `division`, `board`)
  SELECT `id`, `division`, `board` FROM `emp` WHERE `type` = 2;
]]
  db_query(query)

  drop_table('emp')
end


-- --------------------------------------------------------------------------------------------------------------------- Benchmark functions


--- Execute the benchmark queries.
-- Is called during the run command of sysbench.
function benchmark()
  -- @todo Implement delete benchmark.
end
