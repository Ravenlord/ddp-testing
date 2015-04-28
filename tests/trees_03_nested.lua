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
 - Benchmark file for design problem "Trees", "Nested Sets" solution.
 -
 - @author Markus Deutschl <deutschl.markus@gmail.com>
 - @copyright 2014 Markus Deutschl
 - @license http://unlicense.org/ Unlicense
--]]


-- --------------------------------------------------------------------------------------------------------------------- Includes


pathtest = string.match(test, "(.*/)") or ""

dofile(pathtest .. "common.lua")


-- --------------------------------------------------------------------------------------------------------------------- Preparation functions


--- Prepare data for the benchmark.
--  Is called during the prepare command of sysbench in common.lua.
function prepare_data()
  local query
  query = [[
CREATE TABLE `animals` (
  `id` INTEGER UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `name` VARCHAR(255) NOT NULL,
  `left` INTEGER UNSIGNED NOT NULL,
  `right` INTEGER UNSIGNED NOT NULL,
  INDEX (`left`),
  INDEX (`right`)
)
]]
  db_query(query)
  db_query("INSERT INTO `animals` SET `name` = 'carnivore', `left` = 100, `right` = 2000")
  db_query("INSERT INTO `animals` SET `name` = 'feline', `left` = 200, `right` = 1100")
  db_query("INSERT INTO `animals` SET `name` = 'cat', `left` = 300, `right` = 400")
  db_query("INSERT INTO `animals` SET `name` = 'big cat', `left` = 500, `right` = 1000")
  db_query("INSERT INTO `animals` SET `name` = 'tiger', `left` = 600, `right` = 700")
  db_query("INSERT INTO `animals` SET `name` = 'lion', `left` = 800, `right` = 900")

  db_query("INSERT INTO `animals` SET `name` = 'canine', `left` = 1200, `right` = 1900")
  db_query("INSERT INTO `animals` SET `name` = 'dog', `left` = 1300, `right` = 1400")
  db_query("INSERT INTO `animals` SET `name` = 'wolf', `left` = 1500, `right` = 1600")
  db_query("INSERT INTO `animals` SET `name` = 'fox', `left` = 1700, `right` = 1800")
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
--  Is called during the run command of sysbench.
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
