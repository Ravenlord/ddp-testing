pathtest = string.match(test, "(.*/)") or ""

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
  local err, fh, line, numeric, query, stringi
  
  -- Create table for last names.
  query = [[
CREATE TABLE `last_names` (
  `last_name` VARCHAR(20) PRIMARY KEY
)
]]
  db_query(query)
  -- Insert test data from file.
  fh, err = io.open(pathtest .. 'last_names.txt')
  if fh == nil then
    print('Error opening file: ' .. err)
  end
  
  line = fh:read()
  db_bulk_insert_init('INSERT INTO `last_names`(`last_name`) VALUES')
  while line ~= nil do
    db_bulk_insert_next("('" .. line .. "')")
    line = fh:read()
  end
  fh:close()
  db_bulk_insert_done()
  
    -- Create table for first names.
  query = [[
CREATE TABLE `first_names` (
  `first_name` VARCHAR(20) PRIMARY KEY
)
]]
  db_query(query)
  -- Insert test data from file.
  fh, err = io.open(pathtest .. 'first_names.txt')
  if fh == nil then
    print('Error opening file: ' .. err)
  end
  
  line = fh:read()
  db_bulk_insert_init('INSERT INTO `first_names`(`first_name`) VALUES')
  while line ~= nil do
    db_bulk_insert_next("('" .. line .. "')")
    line = fh:read()
  end
  fh:close()
  db_bulk_insert_done()
  
  -- Create table for integers.
  query = [[
CREATE TABLE `integers` (
  `value` INTEGER UNSIGNED PRIMARY KEY
)
]]
  db_query(query)
  -- Insert the numbers.
  db_bulk_insert_init('INSERT INTO `integers`(`value`) VALUES')
  for i = 1, 1000000 do
    db_bulk_insert_next('(' .. i .. ')')
  end
  db_bulk_insert_done()
  
  -- Create table for numeric (fixed point) numbers.
  query = [[
CREATE TABLE `numerics` (
  `value` NUMERIC(7,2) PRIMARY KEY
)
]]
  db_query(query)
  -- Insert the numbers.
  db_bulk_insert_init('INSERT INTO `numerics`(`value`) VALUES')
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
end
