pathtest = string.match(test, "(.*/)") or ""

-- Dummy function to prevent errors if this file is accidentally run as test.
function thread_init(thread_id)
  return 0
end

-- Dummy function to prevent errors if this file is accidentally run as test.
function event(thread_id)
  return 0
end

-- Create test data tables and populate them with data.
function prepare()
  local chunk_size = 10
  local i
  local query
  local fh
  local err
  local line
  
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
end
