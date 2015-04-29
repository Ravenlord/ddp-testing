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
 - Benchmark file for design problem "Attribute Clutter", trivial solution.
 -
 - @author Markus Deutschl <deutschl.markus@gmail.com>
 - @copyright 2014 Markus Deutschl
 - @license http://unlicense.org/ Unlicense
--]]


-- --------------------------------------------------------------------------------------------------------------------- Includes


pathtest = string.match(test, "(.*/)") or ""

dofile(pathtest .. "../common.inc")


-- --------------------------------------------------------------------------------------------------------------------- Preparation functions


--- Prepare data for the benchmark.
--  Is called during the prepare command of sysbench in common.lua.
function prepare_data()
  local query
  prepare_departments('emp_dep', 1000)
  prepare_images('emp_img', 1000, '/tmp/image.png')
  prepare_person_names('emp_nam', 1000)
  prepare_phone_numbers('emp_pho', 1000)
  prepare_salaries('emp_sal', 100, 10, '0.75')

  -- Create the real employees table.
  query = [[
CREATE TABLE `employees` (
  `id` INTEGER UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `name` VARCHAR(255) NOT NULL,
  `department` VARCHAR(255) NOT NULL,
  `phone` INTEGER(5) UNSIGNED NOT NULL,
  `image` MEDIUMBLOB,
  `base_salary` NUMERIC(7,2) NOT NULL,
  `bonus` NUMERIC(7,2) NOT NULL,
  `tax_rate` NUMERIC(3,2) NOT NULL,
  INDEX `employees_departments` (`department`)
)
]]
  db_query(query)
  -- Insert test data by joining.
  query = [[
INSERT INTO `employees` (`name`, `department`, `phone`, `image`, `base_salary`, `bonus`, `tax_rate`)
  SELECT
    `emp_nam`.`name`,
    `emp_dep`.`department`,
    `emp_pho`.`phone`,
    `emp_img`.`image`,
    `emp_sal`.`base_salary`,
    `emp_sal`.`bonus`,
    `emp_sal`.`tax_rate`
  FROM `emp_nam`
    INNER JOIN `emp_dep` ON `emp_dep`.`id` = `emp_nam`.`id`
    INNER JOIN `emp_pho` ON `emp_pho`.`id` = `emp_nam`.`id`
    INNER JOIN `emp_img` ON `emp_img`.`id` = `emp_nam`.`id`
    INNER JOIN `emp_sal` ON `emp_sal`.`id` = `emp_nam`.`id`
]]
  db_query(query)

  -- Delete unnecessary tables.
  drop_table('emp_dep')
  drop_table('emp_img')
  drop_table('emp_nam')
  drop_table('emp_pho')
  drop_table('emp_sal')
end


-- --------------------------------------------------------------------------------------------------------------------- Benchmark functions

--- Execute the benchmark queries.
--  Is called during the run command of sysbench.
function benchmark()
  rs = db_query("SELECT `id`, `name`, `phone` FROM `employees` WHERE `department` = '" .. departments[sb_rand_uniform(1,10)] .. "' ORDER BY `name` ASC")
end
