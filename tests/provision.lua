pathtest = string.match(test, "(.*/)") or ""

dofile(pathtest .. "common.lua")

-- Dummy function to prevent errors if this file is accidentally run as test.
function thread_init(thread_id)
  return 0
end

-- Dummy function to prevent errors if this file is accidentally run as test.
function event(thread_id)
  return 0
end

-- Dummy function to prevent errors if this file is accidentally run as cleanup task.
function cleanup()
  return 0
end

-- Create test data tables and populate them with data.
function prepare()
  set_vars()
  local end_date, err, fh, line, numeric, query, start_date, stringi

  time = os.date("*t")
  print(("%02d:%02d:%02d"):format(time.hour, time.min, time.sec) .. ' - Preparing test data')

  -- Create table for last names.
  query = [[
CREATE TABLE `]] .. schema_data ..[[`.`last_names` (
  `id` INTEGER UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `last_name` VARCHAR(255)
)
]]
  db_query(query)
  -- Insert test data from file.
  fh, err = io.open(pathtest .. 'last_names.txt')
  if fh == nil then
    print('Error opening file: ' .. err)
  end

  line = fh:read()
  db_bulk_insert_init('INSERT INTO `' .. schema_data .. '`.`last_names`(`last_name`) VALUES')
  while line ~= nil do
    db_bulk_insert_next("('" .. line .. "')")
    line = fh:read()
  end
  fh:close()
  db_bulk_insert_done()

  -- Create table for first names.
  query = [[
CREATE TABLE `]] .. schema_data ..[[`.`first_names` (
  `id` INTEGER UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `first_name` VARCHAR(255)
)
]]
  db_query(query)
  -- Insert test data from file.
  fh, err = io.open(pathtest .. 'first_names.txt')
  if fh == nil then
    print('Error opening file: ' .. err)
  end

  line = fh:read()
  db_bulk_insert_init('INSERT INTO `' .. schema_data .. '`.`first_names`(`first_name`) VALUES')
  while line ~= nil do
    db_bulk_insert_next("('" .. line .. "')")
    line = fh:read()
  end
  fh:close()
  db_bulk_insert_done()

  -- Create table for person names.
  query = [[
CREATE TABLE `]] .. schema_data ..[[`.`names` (
  `id` INTEGER UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `first_name` VARCHAR(255),
  `last_name` VARCHAR(255),
  `name` VARCHAR(255),
  `email` VARCHAR(255)
)
]]
  db_query(query)

  -- Insert 10 million person names as pseudo-random permutations of first and last names.
  query = [[
INSERT INTO `]] .. schema_data ..[[`.`names` (`first_name`, `last_name`, `name`, `email`)
	SELECT
	  `fn`.`first_name`,
	  `ln`.`last_name`,
	  CONCAT_WS(' ', `fn`.`first_name`, `ln`.`last_name`),
    CONCAT(`fn`.`first_name`, '@', `ln`.`last_name`, '.com')
  FROM (
      SELECT DISTINCT `last_name` FROM `]] .. schema_data ..[[`.`last_names` ORDER BY RAND() LIMIT 50000
    ) AS `ln`
     CROSS JOIN
    (
      SELECT DISTINCT `first_name` FROM `]] .. schema_data ..[[`.`first_names` ORDER BY RAND() LIMIT 200
    ) AS `fn`
]]
  db_query(query)

  -- Drop first and last name tables.
  db_query('DROP TABLE `' .. schema_data .. '`.`last_names`')
  db_query('DROP TABLE `' .. schema_data .. '`.`first_names`')

  -- Create table for integers.
  query = [[
CREATE TABLE `]] .. schema_data ..[[`.`integers` (
  `value` INTEGER UNSIGNED PRIMARY KEY
)
]]
  db_query(query)
  -- Insert the numbers.
  db_bulk_insert_init('INSERT INTO `' .. schema_data .. '`.`integers`(`value`) VALUES')
  for i = 1, 1000000 do
    db_bulk_insert_next('(' .. i .. ')')
  end
  db_bulk_insert_done()

  -- Create table for numeric (fixed point) numbers.
  query = [[
CREATE TABLE `]] .. schema_data ..[[`.`numerics` (
  `value` NUMERIC(7,2) PRIMARY KEY
)
]]
  db_query(query)
  -- Insert the numbers.
  db_bulk_insert_init('INSERT INTO `' .. schema_data .. '`.`numerics`(`value`) VALUES')
  for i = 1, 1000000 do
    -- Workaround due to the retarded handling of locales in Lua.
    -- And also due to the fact, that Lua only supports floats out of the box.
    stringi = tostring(i)
    if i < 10 then
      numeric = '0.0' .. stringi
    elseif i < 100 then
      numeric = '0.' .. stringi
    else
      numeric = string.sub(stringi, 1, string.len(stringi) - 2) .. '.' .. string.sub(stringi, -2)
    end
    db_bulk_insert_next('(' .. numeric .. ')')
  end
  db_bulk_insert_done()

  -- Create table for random dates.
  query = [[
CREATE TABLE `]] .. schema_data ..[[`.`dates` (
  `id` INTEGER UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `date` DATE
)
]]
  db_query(query)
  -- Approximately sixty years in days.
  start_date = 365 * 60
  -- Approximately eighteen years in days.
  end_date = 365 * 18
  -- Insert the dates.
  db_bulk_insert_init('INSERT INTO `' .. schema_data .. '`.`dates`(`date`) VALUES')
  for i = 1, 1000000 do
    db_bulk_insert_next("(NOW() - INTERVAL " .. sb_rand_uniform(start_date, end_date) .. " DAY)")
  end
  db_bulk_insert_done()
  time = os.date("*t")
  print(("%02d:%02d:%02d"):format(time.hour, time.min, time.sec) .. ' - Done')
end
