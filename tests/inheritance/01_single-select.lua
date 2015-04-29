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
 - Benchmark file for design problem "Inheritance", solution "Single Table Inheritance".
 -
 - @author Markus Deutschl <deutschl.markus@gmail.com>
 - @copyright 2014 Markus Deutschl
 - @license http://unlicense.org/ Unlicense
--]]


-- --------------------------------------------------------------------------------------------------------------------- Includes


pathtest = string.match(test, "(.*/)") or ""

dofile(pathtest .. "../common.inc")


-- --------------------------------------------------------------------------------------------------------------------- Preparation functions

--- Prepare data for the benchmarks.
-- Own function for reusability in the other patterns.
function prepare_schema()
  local query
  prepare_person_names('emp_nam', 1000)
  prepare_phone_numbers('emp_pho', 1000)
  prepare_departments('man_div', 200)
  prepare_departments('man_boa', 50)
  prepare_dates('con_dat', 400)


  -- Create the employees table.
  query = [[
CREATE TABLE `employees` (
  `id` INTEGER UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `type` INTEGER(2) UNSIGNED NOT NULL,
  `name` VARCHAR(255) NOT NULL,
  `office` INTEGER(3) UNSIGNED,
  `phone` INTEGER(5) UNSIGNED,
  `division` VARCHAR(255),
  `board` VARCHAR(255),
  `project` VARCHAR(255),
  `start_date` DATE,
  `end_date` DATE,
  INDEX `employees_types` (`type`)
)
]]
  db_query(query)
  -- Insert regular employees (type code 1).
  query = [[
INSERT INTO `employees` (`type`, `name`, `phone`, `office`)
  SELECT
    1,
    `emp_nam`.`name`,
    `emp_pho`.`phone`,
    FLOOR(RAND() * (900)) + 1
  FROM `emp_nam`
    INNER JOIN `emp_pho` ON `emp_pho`.`id` = `emp_nam`.`id`
  WHERE `emp_nam`.`id` <= 750
]]
  db_query(query)

  -- Insert managers (type code 2).
  query = [[
INSERT INTO `employees` (`type`, `name`, `phone`, `office`, `division`, `board`)
  SELECT
    2,
    `emp_nam`.`name`,
    `emp_pho`.`phone`,
    FLOOR(RAND() * (900)) + 1,
    `man_div`.`department`,
    `man_boa`.`department`
  FROM `emp_nam`
    INNER JOIN `emp_pho` ON `emp_pho`.`id` = `emp_nam`.`id`
    INNER JOIN `man_div` ON `man_div`.`id` = `emp_nam`.`id` - 750
    INNER JOIN `man_boa` ON `man_boa`.`id` = `emp_nam`.`id` - 750
  WHERE `emp_nam`.`id` > 750 AND `emp_nam`.`id` <= 800
]]
  db_query(query)

  -- Insert contractors (type code 3).
  query = [[
INSERT INTO `employees` (`type`, `name`, `project`, `start_date`, `end_date`)
  SELECT
    3,
    `emp_nam`.`name`,
    `man_div`.`department`,
    `date1`.`date`,
    `date2`.`date`
  FROM `emp_nam`
    INNER JOIN `emp_pho` ON `emp_pho`.`id` = `emp_nam`.`id`
    INNER JOIN `man_div` ON `man_div`.`id` = `emp_nam`.`id` - 800
    INNER JOIN `con_dat` AS `date1` ON `date1`.`id` = `emp_nam`.`id` - 800
    INNER JOIN `con_dat` AS `date2` ON `date2`.`id` = `emp_nam`.`id` - 600
  WHERE `emp_nam`.`id` > 800
]]
  db_query(query)

  -- Drop unnecessary tables.
  drop_table('emp_nam')
  drop_table('emp_pho')
  drop_table('man_div')
  drop_table('man_boa')
  drop_table('con_dat')
end

--- Prepare data for the benchmark.
--  Is called during the prepare command of sysbench in common.lua.
function prepare_data()
  prepare_schema()
end


-- --------------------------------------------------------------------------------------------------------------------- Benchmark functions


--- Execute the benchmark queries.
-- Is called during the run command of sysbench.
function benchmark()
  -- @todo Implement delete benchmark.
end
