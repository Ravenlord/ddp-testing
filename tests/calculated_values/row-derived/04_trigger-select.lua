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
 - Benchmark file for design problem "Attribute Clutter", trigger solution.
 - Select single product (random id).
 -
 - @author Markus Deutschl <deutschl.markus@gmail.com>
 - @copyright 2014 Markus Deutschl
 - @license http://unlicense.org/ Unlicense
--]]


-- --------------------------------------------------------------------------------------------------------------------- Includes


pathtest = string.match(test, "(.*/)") or ""

dofile(pathtest .. "../../common.inc")
dofile(pathtest .. "prepare.inc")


-- --------------------------------------------------------------------------------------------------------------------- Preparation functions


--- Prepare data for the benchmark.
-- Is called during the prepare command of sysbench in common.lua.
function prepare_data()
  local query
  -- Reuse the data preparation.
  prepare_row_derived()

  -- Add the new column.
  query = [[
ALTER TABLE `products`
  ADD COLUMN `price` NUMERIC(7,2) AFTER `vat_rate`
]]
  db_query(query)
  -- Prepopulate the calculated values.
  query = [[
UPDATE `products` SET `price` = `base_price` * (1 + `vat_rate`)
]]
  db_query(query)
  -- Create the triggers.
  query = [[
CREATE TRIGGER `products_insert_trigger`
BEFORE INSERT ON `products`
FOR EACH ROW
BEGIN
  SET NEW.`price` = NEW.`base_price` * (1 + NEW.`vat_rate`);
END;
]]
  db_query(query)
  query = [[
CREATE TRIGGER `products_update_trigger`
BEFORE UPDATE ON `products`
FOR EACH ROW
BEGIN
  SET NEW.`price` = NEW.`base_price` * (1 + NEW.`vat_rate`);
END;
]]
  db_query(query)
end


-- --------------------------------------------------------------------------------------------------------------------- Benchmark functions


--- Execute the benchmark queries.
-- Is called during the run command of sysbench.
function benchmark()
 rs = db_query('SELECT * FROM `products` WHERE `id` = ' .. sb_rand_uniform(1, 10000))
end
