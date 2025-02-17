local vim = vim or {}

math.randomseed(os.time())

local uniform = function(entries)
	local statetable = {}
	local p = 1 / #entries
	for i, entry in ipairs(entries) do
		statetable[i] = { p, entry }
	end
	return statetable
end

local chooserandom = function(probabilitytable)
	local num = math.random()
	local sum = 0
	for _, entry in ipairs(probabilitytable) do
		sum = sum + entry[1]
		if num < sum then
			return entry[2]
		end
	end

	return nil
end

local statetable = uniform({
	"You hear a saxophone in the distance. Comment on that.",
	"You hear a truck in the distance. Comment on that.",
})

local motm = function()
	local prompt = {}

	-- Provide today's date, for relative comments
	table.insert(prompt, "Today's date:")
	local date = os.date("%c")
	table.insert(prompt, date)

	-- Give some random context
	table.insert(prompt, chooserandom(statetable))

	table.insert(prompt, "The output on docker ps is: ```")
	table.insert(prompt, vim.system { "docker", "ps" }:wait().stdout)
	table.insert(prompt, "```")

	table.insert(prompt, "The battery statistics on the user's Macbook are currently:")
	local batt = vim.system { "pmset", "-g", "batt" }:wait().stdout
	table.insert(prompt, batt);

  local ps = table.concat(prompt, '\n')
  print(ps)

	local obj = vim.system {
		"ollama", "run", "smelly-noire",
    ps,
	}:wait()

  return obj.stdout
end

local opts = { range = true, nargs = "*", desc = "Word salad" }
vim.api.nvim_create_user_command("SmellyNoire", function() print(motm()) end, opts)
