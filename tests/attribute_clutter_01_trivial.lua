pathtest = string.match(test, "(.*/)") or ""

dofile(pathtest .. "common.lua")

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

-- Dummy function to prevent errors if this file is accidentally run as cleanup task.
function cleanup()
  return 0
end

function prepare_data()
  local fh, image, image_value, query, time
  set_vars()

  time = os.date("*t")
  print('emp_sal ' .. ("%02d:%02d:%02d"):format(time.hour, time.min, time.sec))
  -- Create a table for pseudo-random combinations of base_salaries and boni.
  query = [[
CREATE TABLE `emp_sal` (
  `id` INTEGER UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `base_salary` NUMERIC(7,2) NOT NULL,
  `bonus` NUMERIC(7,2) NOT NULL
)
]]
  db_query(query)
  -- Insert the pseudo-random combinations.
  query = [[
INSERT INTO `emp_sal` (`base_salary`, `bonus`)
  SELECT `num1`.`value`, `num2`.`value`
    FROM (
      SELECT `value` FROM `]] .. schema_data .. [[`.`numerics` ORDER BY RAND() LIMIT 100
    ) AS `num1`
    CROSS JOIN (
      SELECT `value` FROM `]] .. schema_data .. [[`.`numerics` ORDER BY RAND() LIMIT 10
    ) AS `num2`
]]
  db_query(query)

  time = os.date("*t")
  print('emp_nam ' .. ("%02d:%02d:%02d"):format(time.hour, time.min, time.sec))
  -- Create a table for person names.
  query = [[
CREATE TABLE `emp_nam` (
  `id` INTEGER UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `name` VARCHAR(255) NOT NULL
)
]]
  db_query(query)
  -- Obtain 1000 random person names.
  query = [[
INSERT INTO `emp_nam` (`name`)
  SELECT DISTINCT `name` FROM `]] .. schema_data .. [[`.`names` LIMIT 1000
]]
  db_query(query)

  time = os.date("*t")
  print('emp_pho ' .. ("%02d:%02d:%02d"):format(time.hour, time.min, time.sec))
  -- Create a table for random "phone numbers".
  query = [[
CREATE TABLE `emp_pho` (
  `id` INTEGER UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `phone` INTEGER(5) NOT NULL
)
]]
  db_query(query)
  -- Obtain 1000 random phone numbers.
  query = [[
INSERT INTO `emp_pho` (`phone`)
  SELECT `value` FROM `]] .. schema_data .. [[`.`integers` WHERE `value` < 100000 ORDER BY RAND() LIMIT 1000
]]
  db_query(query)

  time = os.date("*t")
  print('emp_dep ' .. ("%02d:%02d:%02d"):format(time.hour, time.min, time.sec))
  -- Create a table for departments and images with 75% images present.
  query = [[
CREATE TABLE `emp_dep` (
  `id` INTEGER UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `department` VARCHAR(255) NOT NULL,
  `image` MEDIUMBLOB
)
]]
  db_query(query)
  -- Insert the departments and images.
  image = "LOAD_FILE('/tmp/image.png')"

  db_bulk_insert_init('INSERT INTO `emp_dep` (`department`, `image`) VALUES')
  for i = 1, 1000 do
    if i % 4 == 0 then
      image_value = image
    else
      image_value = 'NULL'
    end
    db_bulk_insert_next("('" .. departments[sb_rand_uniform(1,10)] .. "', " .. image_value ..")")
  end
  db_bulk_insert_done()

  time = os.date("*t")
  print('employees ' .. ("%02d:%02d:%02d"):format(time.hour, time.min, time.sec))
  -- Finally, create the real employees table.
  query = [[
CREATE TABLE `employees` (
  `id` INTEGER UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `name` VARCHAR(255) NOT NULL,
  `department` VARCHAR(255) NOT NULL,
  `phone` INTEGER(5) UNSIGNED NOT NULL,
  `image` MEDIUMBLOB,
  `base_salary` NUMERIC(7,2) NOT NULL,
  `bonus` NUMERIC(7,2) NOT NULL,
  `tax_rate` NUMERIC(3,2) NOT NULL DEFAULT 0.75,
  INDEX `employees_departments` (`department`)
)
]]
  db_query(query)
  -- Insert test data by joining.
  query = [[
INSERT INTO `employees` (`name`, `department`, `phone`, `image`, `base_salary`, `bonus`)
  SELECT `emp_nam`.`name`, `emp_dep`.`department`, `emp_pho`.`phone`, `emp_dep`.`image`, `emp_sal`.`base_salary`, `emp_sal`.`bonus`
    FROM `emp_nam`
      INNER JOIN `emp_dep` ON `emp_dep`.`id` = `emp_nam`.`id`
      INNER JOIN `emp_pho` ON `emp_pho`.`id` = `emp_nam`.`id`
      INNER JOIN `emp_sal` ON `emp_sal`.`id` = `emp_nam`.`id`
]]
  db_query(query)

  time = os.date("*t")
  print('done ' .. ("%02d:%02d:%02d"):format(time.hour, time.min, time.sec))
  db_query('DROP TABLE `emp_sal`')
  db_query('DROP TABLE `emp_nam`')
  db_query('DROP TABLE `emp_pho`')
  db_query('DROP TABLE `emp_dep`')
end

function prepare()
  prepare_data()
end

function thread_init(thread_id)
  set_vars()
end

function event(thread_id)
  rs = db_query("SELECT `id`, `name`, `phone` FROM `employees` WHERE `department` = '" .. departments[sb_rand_uniform(1,10)] .. "' ORDER BY `name` ASC")
end
