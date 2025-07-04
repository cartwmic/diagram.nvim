---@class MermaidOptions
---@field background? string
---@field theme? string
---@field scale? number
---@field width? number
---@field height? number

---@type table<string, string>

---@class Renderer<MermaidOptions>
local M = {
	id = "mermaid",
}

-- fs cache
local cache_dir = vim.fn.resolve(vim.fn.stdpath("cache") .. "/diagram-cache/mermaid")
vim.fn.mkdir(cache_dir, "p")

---@param source string
---@param options MermaidOptions
---@return table|nil
M.render = function(source, options)
	local hash = vim.fn.sha256(M.id .. ":" .. source)
	local path = vim.fn.resolve(cache_dir .. "/" .. hash .. ".png")
	if vim.fn.filereadable(path) == 1 then
		return { file_path = path }
	end

	if not vim.fn.executable("mmdc") then
		error("diagram/mermaid: mmdc not found in PATH")
	end

	local tmpsource = vim.fn.tempname()
	vim.fn.writefile(vim.split(source, "\n"), tmpsource)

	local command_parts = {
		"mmdc",
		"-i",
		tmpsource,
		"-o",
		path,
	}
	if options.background then
		table.insert(command_parts, "-b")
		table.insert(command_parts, options.background)
	end
	if options.theme then
		table.insert(command_parts, "-t")
		table.insert(command_parts, options.theme)
	end
	if options.scale then
		table.insert(command_parts, "-s")
		table.insert(command_parts, options.scale)
	end
	if options.width then
		table.insert(command_parts, "--width")
		table.insert(command_parts, options.width)
	end
	if options.height then
		table.insert(command_parts, "--height")
		table.insert(command_parts, options.height)
	end

	local command = table.concat(command_parts, " ")

	local job_id = vim.fn.jobstart(command, {
		on_stdout = function(job_id, data, event) end,
		on_stderr = function(job_id, data, event)
			if next(data) == nil or data == nil then
				return nil
			end

			local actual_error = false
			for _, value in pairs(data) do
				if value ~= "" or value ~= nil then
					actual_error = true
				end
			end

			if not actual_error then
				return nil
			end
			local error_msg = table.concat(data, "\n")
			vim.notify("diagram/mermaid: mmdc failed to render diagram. Error: " .. error_msg, vim.log.levels.ERROR)
			return nil
		end,
		on_exit = function(job_id, exit_code, event)
			-- local msg = string.format("Job %d exited with code %d.", job_id, exit_code)
			-- vim.api.nvim_out_write(msg .. "\n")
		end,
	})
	return { file_path = path, job_id = job_id }
end

return M
