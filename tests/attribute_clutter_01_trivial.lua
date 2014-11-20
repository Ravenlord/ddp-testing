pathtest = string.match(test, "(.*/)") or ""

dofile(pathtest .. "common.lua")

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

function event(thread_id)
  rs = db_query("SELECT `id`, `name`, `phone` FROM `employees` WHERE `department` = '" .. departments[sb_rand_uniform(1,10)] .. "' ORDER BY `name` ASC")
end
