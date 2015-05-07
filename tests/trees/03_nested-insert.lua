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
 - Insert intermediate node "four-legged" between "carnivore" and its children.
 -
 - @author Markus Deutschl <deutschl.markus@gmail.com>
 - @copyright 2014 Markus Deutschl
 - @license http://unlicense.org/ Unlicense
--]]


-- --------------------------------------------------------------------------------------------------------------------- Includes


pathtest = string.match(test, "(.*/)") or ""

dofile(pathtest .. "../common.inc")
dofile(pathtest .. "prepare.inc")


-- --------------------------------------------------------------------------------------------------------------------- Preparation functions


--- Implement the appropriate insert function.
-- Is called during tree traversal in prepare_tree().
function Node:insertPost()
  db_query("INSERT INTO `animals` SET `id` = " .. self.id .. ", `name` = '" .. self.name .. "', `left` = " .. (self.leftnum * 100) .. ", `right` = " .. (self.rightnum * 100))
end

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
  prepare_tree()
end


-- --------------------------------------------------------------------------------------------------------------------- Benchmark functions


--- Execute the benchmark queries.
-- Is called during the run command of sysbench.
function benchmark()
  db_query('BEGIN')
  rs = db_query("INSERT INTO `animals` (`id`, `name`, `left`, `right`) VALUES (11, 'four-legged', 150, 1950)")
  db_query('ROLLBACK')
end
