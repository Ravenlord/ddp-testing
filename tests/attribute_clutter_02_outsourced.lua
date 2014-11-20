pathtest = string.match(test, "(.*/)") or ""

dofile(pathtest .. "common.lua")

-- Dummy function to prevent errors if this file is accidentally run as cleanup task.
function cleanup()
  return 0
end

-- Prepare the test data tables, which can then be reused by the tests.
function prepare_data()
  local query
  prepare_departments('emp_dep', 1000)
  prepare_images('employee_profiles', 1000, '/tmp/image.png')
  prepare_person_names('emp_nam', 1000)
  prepare_phone_numbers('emp_pho', 1000)
  prepare_salaries('employee_accounting', 100, 10, '0.75')


  -- Create the employees table.
  query = [[
CREATE TABLE `employees` (
  `id` INTEGER UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `name` VARCHAR(255) NOT NULL,
  `department` VARCHAR(255) NOT NULL,
  `phone` INTEGER(5) NOT NULL,
  INDEX `employees_departments` (`department`)
)
]]
  db_query(query)
  -- Insert test data by joining.
  query = [[
INSERT INTO `employees` (`name`, `department`, `phone`)
  SELECT
    `emp_nam`.`name`,
    `emp_dep`.`department`,
    `emp_pho`.`phone`
  FROM `emp_nam`
    INNER JOIN `emp_dep` ON `emp_dep`.`id` = `emp_nam`.`id`
    INNER JOIN `emp_pho` ON `emp_pho`.`id` = `emp_nam`.`id`
]]
  db_query(query)

  -- Delete null rows from images table.
  db_query('DELETE FROM `employee_profiles` WHERE `image` IS NULL')

  -- Create foreign keys on dependent tables.
  db_query('ALTER TABLE `employee_accounting` ADD FOREIGN KEY (`id`) REFERENCES `employees`(`id`) ON DELETE CASCADE ON UPDATE CASCADE')
  db_query('ALTER TABLE `employee_profiles` ADD FOREIGN KEY (`id`) REFERENCES `employees`(`id`) ON DELETE CASCADE ON UPDATE CASCADE')

  -- Drop unnecessary tables.
  drop_table('emp_dep')
  drop_table('emp_nam')
  drop_table('emp_pho')
end

function event(thread_id)
  rs = db_query("SELECT `id`, `name`, `phone` FROM `employees` WHERE `department` = '" .. departments[sb_rand_uniform(1,10)] .. "' ORDER BY `name` ASC")
end
