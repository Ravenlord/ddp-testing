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
 - Common, reusable functions for the benchmarks.
 -
 - @author Markus Deutschl <deutschl.markus@gmail.com>
 - @copyright 2014 Markus Deutschl
 - @license http://unlicense.org/ Unlicense
--]]

-- Global array for easy access.
departments = {
   'Accounting',
   'Customer Services',
   'Finance',
   'Human Resources',
   'IT',
   'Management',
   'Operations',
   'Quality Assurance',
   'Research and Development',
   'Sales'
}

--- Clean up all resources used by the benchmark.
--  Is called during the cleanup command of sysbench.
--  Dummy implementation, due to schema drop after every benchmark run.
function cleanup()
  return 0
end

--- Drop a database table.
-- @param name  The table name to drop.
function drop_table(name)
  db_query('DROP TABLE `' .. name .. '`')
end

--- Generic prepare function used for timing.
function prepare()
  set_vars()
  local time
  time = os.date("*t")
  print(("%02d:%02d:%02d"):format(time.hour, time.min, time.sec) .. ' - Preparing test data')
  prepare_data()
  time = os.date("*t")
  print(("%02d:%02d:%02d"):format(time.hour, time.min, time.sec) .. ' - Preparation complete')
end

--- Prepare a table with dates.
-- @param name     The name of the table.
-- @param number   Defines how many dates will be generated.
function prepare_dates(name, number)
  local query
  query = [[
CREATE TABLE `]] .. name .. [[` (
  `id` INTEGER UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `date` DATE NOT NULL
)
]]
  db_query(query)
  query = [[
INSERT INTO `]] .. name .. [[` (`date`)
  SELECT `date` FROM `]] .. schema_data .. [[`.`dates` ORDER BY RAND() LIMIT ]] .. number
  db_query(query)
end

--- Prepare a table with department names randomly distributed (uniform).
-- @param   name     The name of the table.
-- @param   number   Defines how many rows will be generated.
function prepare_departments(name, number)
   local query, size
   query = [[
CREATE TABLE `]] .. name .. [[` (
  `id` INTEGER UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `department` VARCHAR(255) NOT NULL
)
]]
   db_query(query)
   -- Insert the departments.
   size = table.getn(departments)
   db_bulk_insert_init('INSERT INTO `' .. name .. '` (`department`) VALUES')
   for i = 1, number do
      db_bulk_insert_next("('" .. departments[sb_rand_uniform(1,size)] .. "')")
   end
   db_bulk_insert_done()
end

--- Prepare a table for file paths with 80% paths present.
-- @param name     The name of the table.
-- @param number   Defines how many rows will be generated.
function prepare_file_paths(name, number)
  local path_value, query, random_max, random_string
  query = [[
CREATE TABLE `]] .. name .. [[` (
  `id` INTEGER UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `path` VARCHAR(255)
)
]]
  db_query(query)
  -- Insert the images, 20% of the rows will have NULL values.
  db_bulk_insert_init('INSERT INTO `'.. name .. '` (`path`) VALUES')
  for i = 1, number do
    if i % 5 == 0 then
      path_value = 'NULL'
    else
      -- File name of variable length.
      random_max    = sb_rand_uniform(5,239)
      random_string = ''
      for j = 1, random_max do
        random_string = random_string .. '#'
      end
      path_value = sb_rand_str('/tmp/images/' .. random_string .. '.png')
    end
    db_bulk_insert_next("('" .. path_value .. "')")
  end
  db_bulk_insert_done()
end

--- Prepare a table for images with 80% images present.
-- @param name     The name of the table.
-- @param number   Defines how many rows will be generated.
-- @param path     The path to the image.
function prepare_images(name, number, path)
  local image, image_value, query
  query = [[
CREATE TABLE `]] .. name .. [[` (
  `id` INTEGER UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `image` MEDIUMBLOB
)
]]
  db_query(query)
  -- Insert the images, 20% of the rows will have NULL values.
  image = "LOAD_FILE('" .. path .. "')"
  db_bulk_insert_init('INSERT INTO `'.. name .. '` (`image`) VALUES')
  for i = 1, number do
    if i % 5 == 0 then
      image_value = 'NULL'
    else
      image_value = image
    end
    db_bulk_insert_next("(" .. image_value .. ")")
  end
  db_bulk_insert_done()
end

--- Prepare a table with person names and email addresses.
-- @param name     The name of the table.
-- @param number   Defines how many rows will be generated.
function prepare_person_names(name, number)
  local query
  query = [[
CREATE TABLE `]] .. name .. [[` (
  `id` INTEGER UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `name` VARCHAR(255) NOT NULL,
  `email` VARCHAR(255) NOT NULL
)
]]
  db_query(query)
  query = [[
INSERT INTO `]] .. name .. [[` (`name`, `email`)
  SELECT DISTINCT `name`, `email` FROM `]] .. schema_data .. [[`.`names` LIMIT ]] .. number
  db_query(query)
end

--- Prepare a table with phone numbers (length 5).
-- @param name     The name of the table.
-- @param number   Defines how many phone numbers will be generated.
function prepare_phone_numbers(name, number)
  local query
  query = [[
CREATE TABLE `]] .. name .. [[` (
  `id` INTEGER UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `phone` INTEGER(5) NOT NULL
)
]]
  db_query(query)
  query = [[
INSERT INTO `]] .. name .. [[` (`phone`)
  SELECT `value` FROM `]] .. schema_data .. [[`.`integers` WHERE `value` < 100000 ORDER BY RAND() LIMIT ]] .. number
  db_query(query)
end

--- Prepare a table basic salary information.
-- Consists of the fields 'base_salary', 'bonus' and 'tax_rate' (fixed).
-- The total number of rows is determined by num_base_salaries * num_boni,
-- which is a permutation of random fixed point numbers.
-- @param name              The name of the table.
-- @param num_base_salaries Defines how many random base salaries will be generated.
-- @param num_boni          Defines how many random boni will be generated.
-- @param tax_rate          The fixed tax rate to insert.
function prepare_salaries(name, num_base_salaries, num_boni, tax_rate)
  local query
  query = [[
CREATE TABLE `]] .. name .. [[` (
  `id` INTEGER UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `base_salary` NUMERIC(7,2) NOT NULL,
  `bonus` NUMERIC(7,2) NOT NULL,
  `tax_rate` NUMERIC(3,2) NOT NULL
)
]]
  db_query(query)
  -- Insert the pseudo-random combinations.
  query = [[
INSERT INTO `]] .. name .. [[` (`base_salary`, `bonus`, `tax_rate`)
  SELECT `num1`.`value`, `num2`.`value`, ]] .. tax_rate .. [[
    FROM (
      SELECT `value` FROM `]] .. schema_data .. [[`.`numerics` ORDER BY RAND() LIMIT ]] .. num_base_salaries .. [[
    ) AS `num1`
    CROSS JOIN (
      SELECT `value` FROM `]] .. schema_data .. [[`.`numerics` ORDER BY RAND() LIMIT ]] .. num_boni .. [[
    ) AS `num2`
]]
  db_query(query)
end

--- Set variables provided on the command line.
function set_vars()
   oltp_table_size = oltp_table_size or 10000
   oltp_range_size = oltp_range_size or 100
   oltp_tables_count = oltp_tables_count or 1
   oltp_point_selects = oltp_point_selects or 10
   oltp_simple_ranges = oltp_simple_ranges or 1
   oltp_sum_ranges = oltp_sum_ranges or 1
   oltp_order_ranges = oltp_order_ranges or 1
   oltp_distinct_ranges = oltp_distinct_ranges or 1
   oltp_index_updates = oltp_index_updates or 1
   oltp_non_index_updates = oltp_non_index_updates or 1
   schema_data = schema_data or "data"

   if (oltp_auto_inc == 'off') then
      oltp_auto_inc = false
   else
      oltp_auto_inc = true
   end

   if (oltp_read_only == 'on') then
      oltp_read_only = true
   else
      oltp_read_only = false
   end

   if (oltp_skip_trx == 'on') then
      oltp_skip_trx = true
   else
      oltp_skip_trx = false
   end

end

--- Initialize benchmark threads.
function thread_init(thread_id)
  set_vars()
end
