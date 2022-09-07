local M = {}

M.split = function (s, delimiter)
    local result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end

M.get_file_in_cloud = function ()
    local current_file_path = vim.api.nvim_buf_get_name(0)
    local curr_file_split = M.split(current_file_path, "/")

    local idx = nil
    local file_path_in_cloud_table = {}

    for i, v in ipairs(curr_file_split) do
        if v == "cartridge" then
            idx = i - 1 -- returning always -1 because we want to know the path including the cartridge name.
        end

        if idx then
            table.insert(file_path_in_cloud_table, v)
        end
    end

    table.insert(file_path_in_cloud_table, 1, curr_file_split[idx])

    local file_in_cloud = ''

    for i, v in ipairs(file_path_in_cloud_table) do
        file_in_cloud = file_in_cloud.."/"..v
    end

    return file_in_cloud
end

return M
