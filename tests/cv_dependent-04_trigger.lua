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
 - Benchmark file for design problem "Calculated Values (dependent)", Trigger solution.
 -
 - @author Markus Deutschl <deutschl.markus@gmail.com>
 - @copyright 2014 Markus Deutschl
 - @license http://unlicense.org/ Unlicense
--]]


-- --------------------------------------------------------------------------------------------------------------------- Includes


pathtest = string.match(test, "(.*/)") or ""

dofile(pathtest .. "common.lua")
dofile(pathtest .. "cv_dependent-01_trivial.lua")


-- --------------------------------------------------------------------------------------------------------------------- Preparation functions


--- Prepare data for the benchmark.
-- Is called during the prepare command of sysbench in common.lua.
function prepare_data()
  local query
  -- Reuse data preparation.
  prepare_dependent()

  -- Add the new column.
  query = [[
ALTER TABLE `products`
  ADD COLUMN `amount_ordered` INTEGER UNSIGNED AFTER `price`
]]
  db_query(query)
  -- Prepopulate the calculated values.
  query = [[
UPDATE `products` SET `amount_ordered` = (SELECT SUM(`amount`) FROM `line_items` WHERE `product_id` = `id`)
]]
  db_query(query)

  -- Create the triggers.
  query = [[
CREATE TRIGGER `products_amount_insert_trigger`
AFTER INSERT ON `line_items`
FOR EACH ROW
BEGIN
  UPDATE `products`
    SET `amount_ordered` = `amount_ordered` + NEW.`amount`
    WHERE `products`.`id` = NEW.`product_id`;
END;
]]
  db_query(query)

  query = [[
CREATE TRIGGER `products_amount_update_trigger`
AFTER UPDATE ON `line_items`
FOR EACH ROW
BEGIN
  IF OLD.`product_id` != NEW.`product_id`
  THEN
    UPDATE `products`
      SET `amount_ordered` = `amount_ordered` - OLD.`amount`
      WHERE `products`.`id` = OLD.`product_id`;
    UPDATE `products`
      SET `amount_ordered` = `amount_ordered` + NEW.`amount`
      WHERE `products`.`id` = NEW.`product_id`;
  ELSE
    UPDATE `products`
      SET `amount_ordered` = `amount_ordered` + NEW.`amount` - OLD.`amount`
      WHERE `products`.`id` = NEW.`product_id`;
  END IF;
END;
]]
  db_query(query)

  query = [[
CREATE TRIGGER `products_amount_delete_trigger`
AFTER DELETE ON `line_items`
FOR EACH ROW
BEGIN
  UPDATE `products`
    SET `amount_ordered` = `amount_ordered` - OLD.`amount`
    WHERE `products`.`id` = OLD.`product_id`;
END;
]]
  db_query(query)
  fail()
end


-- --------------------------------------------------------------------------------------------------------------------- Benchmark functions


--- Execute the delete benchmark queries.
-- Is called during the run command of sysbench.
function benchmark_delete()
  -- @todo Implement delete benchmark.
end

--- Execute the insert benchmark queries.
-- Is called during the run command of sysbench.
function benchmark_insert()
  -- @todo Implement insert benchmark.
end

--- Execute the select benchmark queries.
-- Is called during the run command of sysbench.
function benchmark_select()
  -- @todo Implement select benchmark.
end

--- Execute the update benchmark queries.
-- Is called during the run command of sysbench.
function benchmark_update()
  -- @todo Implement update benchmark.
end


-- --------------------------------------------------------------------------------------------------------------------- Post-parsing setup


dofile(pathtest .. "post_setup.lua")
